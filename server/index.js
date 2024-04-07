const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('njwt');
require('dotenv').config();
const bcrypt = require("bcrypt")
const { exec } = require('child_process');
var cors = require('cors');
const axios = require('axios');
const qs = require('querystring');
const fs = require('fs');
const https = require('https');
const path = require('path');

const app = express();
const PORT = 3004;

var options = {
    key: fs.readFileSync('/etc/letsencrypt/live/rishiroy.com-0001/privkey.pem'),
    cert: fs.readFileSync('/etc/letsencrypt/live/rishiroy.com-0001/fullchain.pem')
};

const corsOptions = {
    origin: "*", // allow access to this origin
    optionsSuccessStatus: 200 // legacy browsers
};

// start server
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cors(corsOptions));
https.createServer(options, app).listen(PORT);

function createJWT(user, expiration_mins) {
    // add identifying information
    const claims = { email: user };
    const token = jwt.create(claims, process.env.SECRET);
    token.setExpiration(new Date().getTime() + (expiration_mins * 60 * 1000));
    return token.compact();
}

function sendEmail(address, subject, body) {
    exec(`osascript -e '
    tell application "Mail"
        set newMessage to (a reference to (make new outgoing message))
        tell newMessage
            make new to recipient at beginning of to recipients ¬
                with properties {address:"${address}"}
            set the sender to "Sortify <${process.env.EMAIL}>"
            set the subject to "${subject}"
            set the content to "${body}"
            send
        end tell
    end tell'`);
}


// open db
let users_db = new sqlite3.Database('./db/users.db');
let incomplete_db = new sqlite3.Database('./db/incomplete-tests.db');
let complete_db = new sqlite3.Database('./db/complete-tests.db');

app.use(express.static(path.join(__dirname, "public")));
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, "public/index.html"))
})

// validate login request, provide jwt token
app.post('/login', (req, res) => {
    console.log("\n/login");

    // parse authentication header
    const auth_header = req.headers.authorization;
    console.log(auth_header);
    if (!auth_header) {
        res.setHeader("WWW-Authenticate", "Basic");
        return res.status(401).send("Unauthorized request");
    }
    let auth = null;
    try {
        auth = new Buffer.from(auth_header.split(" ")[1], "base64").toString().split(":");
    } catch (err) {
        return res.status(400).send("An error occured while parsing the provided basic auth header");
    }
    const user = auth[0];
    const pass = auth[1];

    // validate authentication values
    users_db.get(`SELECT * FROM Users where Email = ?`, [user], (err, row) => {
        if (err)
            return res.status(500).send(err.message); // unknown error
        if (row == null)
            return res.status(422).send("Email not found");
        let db_hash = row.Password;
        // compare hashes
        bcrypt
            .compare(pass, db_hash)
            .then(result => {
                if (result == true) {
                    console.log("Successful");
                    res.send(createJWT(user, 5)); // 5 min jwt
                } else
                    return res.status(401).send("Not successful");
            })
            .catch(err => {
                console.error(err.message);
                res.status(500).send(err.message);
            });
    });
});

// email a verification jwt, required: body.email
app.post("/verify-email", (req, res) => {
    console.log("\n/verify-email");

    const email = req.body.email;
    if (email == null)
        return res.status(422).send("Missing email in body");

    const access_token = createJWT(email, 15); // jwt with their email and 15 minute expiration

    const body = `Please enter this access code in the Sortify application\n\n${access_token}\n\nFor your security, we do not provide a direct link.\nIf you did not request to sign up, please disregard this email.`;
    sendEmail(email, "Verify Your Email to Use Sortify", body);
    return res.send("Attempted to send email, status unknown");
});

// add a user to the database, required: Email, Password, Name, auth via jwt
app.post("/create-user", (req, res) => {
    console.log("\n/create-user");

    if (req.headers.authorization == null)
        res.status(401).send("Missing JWT authorization");
    let jwt_token = null;
    try {
        jwt_token = req.headers.authorization.toString().split(" ")[1];
    } catch {
        return res.status(400).send("Unable to parse token");
    }
    let email = null;
    const pass = req.body.pass;
    const name = req.body.name;
    // verify jwt
    jwt.verify(jwt_token, process.env.SECRET, (err, verified_jwt) => {
        if (err) {
            if (err.message == "Jwt is expired")
                return res.status(401).send("Code is expired");
            return res.status(401).send(err.message); // invalid jwt
        }
        else {
            console.log("verified jwt:");
            console.log(verified_jwt);
            email = verified_jwt.body.email; // get email from jwt
            // hash password
            bcrypt
                .hash(pass, 5)
                .then(hash => {
                    console.log("hash ", hash);
                    console.log("registering user ", email, name);
                    // insert user into db
                    const query = `INSERT INTO Users(Email, Password, Name) VALUES(?, ?, ?);`
                    users_db.run(query, [email, hash, name], (err) => {
                        if (err) {
                            // user already exists error
                            if (err.message.includes("SQLITE_CONSTRAINT: UNIQUE constraint failed:")) {
                                res.status(422).send("User already exists");
                                return console.log("This user already exists!");
                            }
                            // other error
                            console.error(err.message);
                            return res.status(500).send(err.message);
                        } else
                            return res.send("Created user");
                    });
                })
                .catch(err => {
                    console.error(err.message);
                    return res.status(500).send(err.message);
                });
        }
    });
});

app.get('/verify', (req, res) => {
    console.log("\n/verify");

    if (req.headers.authorization == null)
        return res.status(401).send("Missing authorization");

    const token = req.headers.authorization.toString().split(" ")[1];
    jwt.verify(token, process.env.SECRET, (err, verified_jwt) => {
        if (err)
            return res.status(401).send(err.message);
        return res.send("Verified jwt");
    });
});

app.post('/email-status', (req, res) => {
    console.log("\n/email-status");

    if (req.body.email == null)
        return res.status(442).send("Missing body.email");

    users_db.get(`SELECT * FROM users WHERE Email = ?`, [req.body.email], (err, row) => {
        if (err)
            return res.status(500).send(err.message);
        return res.send(row ? "Email is registered" : "Email not registered");
    })
});

// spotify api routes
var spotifyToken = "";

app.post('/spotify/search', async (req, res) => {
    console.log("\n/spotify/search");

    if (req.headers.authorization == null)
        return res.status(401).send("Missing auth token");
    const token = req.headers.authorization.toString().split(" ")[1];
    jwt.verify(token, process.env.SECRET, (err, verified_jwt) => {
        if (err)
            return res.status(401).send(err.message);

        if (req.query.query == null || req.query.type == null)
            return res.status(442).send("Missing query or type in params");

        const query = req.query.query;
        const type = req.query.type;
        const limit = req.query.limit;
        const offset = req.query.offset;

        function searchSpotify(retry) {
            console.log("api.spotify.com/v1/search");
            axios.get("https://api.spotify.com/v1/search", {
                params: {
                    q: query,
                    type: type,
                    limit: limit,
                    offset: offset
                },
                headers: {
                    "Authorization": `Bearer ${spotifyToken}`
                }
            })
                .then(function (response) {
                    return res.send(response.data);
                })
                .catch(function (error) {
                    if (error.response.status === 401 || error.response.data.error.message == "Only valid bearer authentication supported") {
                        console.log("accounts.spotify.com/api/token");
                        axios.post("https://accounts.spotify.com/api/token",
                            qs.stringify({
                                "grant_type": "client_credentials",
                                "client_id": process.env.CLIENT_ID,
                                "client_secret": process.env.CLIENT_SECRET
                            }),
                            {
                                headers: {
                                    "Content-Type": "application/x-www-form-urlencoded"
                                }
                            }
                        )
                            .then(function (response) {
                                console.log("acquired token");
                                spotifyToken = response.data.access_token;
                                if (!retry) {
                                    return res.status(500).send("Unable to authorize for Spotify");
                                }
                                return searchSpotify(false); // second attempt to search after getting token
                            })
                            .catch(function (error) {
                                return res.status(500).send("Could not retrieve data");
                            });
                    }
                });
        }
        searchSpotify(true); // first attempt to search
    });
});

app.post('/spotify/artist-albums', async (req, res) => {
    console.log("\n/spotify/artist-albums");

    if (req.headers.authorization == null)
        return res.status(401).send("Missing auth token");
    const token = req.headers.authorization.toString().split(" ")[1];
    jwt.verify(token, process.env.SECRET, (err, verified_jwt) => {
        if (err)
            return res.status(401).send(err.message);

        if (req.query.id == null)
            return res.status(442).send("Missing id param");

        const id = req.query.id;
        const limit = req.query.limit;
        const offset = req.query.offset;

        function searchSpotify(retry) {
            console.log(`api.spotify.com/v1/artists/${id}/albums`);

            axios.get(`https://api.spotify.com/v1/artists/${id}/albums`, {
                params: {
                    limit: limit,
                    offset: offset
                },
                headers: {
                    "Authorization": `Bearer ${spotifyToken}`
                }
            })
                .then(function (response) {
                    return res.send(response.data);
                })
                .catch(function (error) {
                    if (error.response && (error.response.status === 401 || error.response.data.error.message == "Only valid bearer authentication supported")) {
                        console.log("accounts.spotify.com/api/token");
                        axios.post("https://accounts.spotify.com/api/token",
                            qs.stringify({
                                "grant_type": "client_credentials",
                                "client_id": process.env.CLIENT_ID,
                                "client_secret": process.env.CLIENT_SECRET
                            }),
                            {
                                headers: {
                                    "Content-Type": "application/x-www-form-urlencoded"
                                }
                            })
                            .then(function (response) {
                                console.log("acquired token");
                                spotifyToken = response.data.access_token;
                                searchSpotify(false); // second attempt to search after getting token
                            })
                            .catch(function (error) {
                                return res.status(500).send("Could not retrieve data");
                            });
                    } else {
                        return res.status(500).send("Could not retrieve data");
                    }
                });
        }
        searchSpotify(true); // first attempt to search
    });
});

app.post('/spotify/album-tracks', async (req, res) => {
    console.log("\n/spotify/album-tracks");

    if (req.headers.authorization == null)
        return res.status(401).send("Missing auth token");
    const token = req.headers.authorization.toString().split(" ")[1];
    jwt.verify(token, process.env.SECRET, (err, verified_jwt) => {
        if (err)
            return res.status(401).send(err.message);

        if (req.query.id == null)
            return res.status(442).send("Missing id param");

        const id = req.query.id;
        const limit = req.query.limit;
        const offset = req.query.offset;

        function searchSpotify(retry) {
            console.log(`api.spotify.com/v1/albums/${id}/tracks`);

            axios.get(`https://api.spotify.com/v1/albums/${id}/tracks`, {
                params: {
                    limit: limit,
                    offset: offset
                },
                headers: {
                    "Authorization": `Bearer ${spotifyToken}`
                }
            })
                .then(function (response) {
                    return res.send(response.data);
                })
                .catch(function (error) {
                    if (error.response && (error.response.status === 401 || error.response.data.error.message == "Only valid bearer authentication supported")) {
                        console.log("accounts.spotify.com/api/token");
                        axios.post("https://accounts.spotify.com/api/token",
                            qs.stringify({
                                "grant_type": "client_credentials",
                                "client_id": process.env.CLIENT_ID,
                                "client_secret": process.env.CLIENT_SECRET
                            }),
                            {
                                headers: {
                                    "Content-Type": "application/x-www-form-urlencoded"
                                }
                            })
                            .then(function (response) {
                                console.log("Acquired token");
                                spotifyToken = response.data.access_token;
                                searchSpotify(false); // second attempt to search after getting token
                            })
                            .catch(function (error) {
                                return res.status(500).send("Could not retrieve data");
                            });
                    } else {
                        return res.status(500).send("Could not retrieve data");
                    }
                });
        }
        searchSpotify(true); // first attempt to search
    });
});

// add an incomplete sort to db, requires users and songs
app.post('/create-sort', (req, res) => {
    console.log("\n/create-sort");

    if (!req.body.songs)
        return res.status(400).send("Missing list of songs");
    if (!req.headers.authorization)
        return res.status(401).send("Missing auth token");

    const token = req.headers.authorization.toString().split(" ")[1];
    jwt.verify(token, process.env.SECRET, (err, verified_jwt) => {
        if (err)
            return res.status(401).send(err.message);

        incomplete_db.run(`INSERT INTO Incomplete(Date, User, Songs) VALUES (?, ?, ?)`, [Date.now(), verified_jwt.body.email, req.body.songs], function (err) {
            if (err)
                return res.status(500).send(err.message);
            return res.send(this.lastID.toString());
        });
    });
});

app.get('/get-incomplete-sort', (req, res) => {
    console.log("\n/get-incomplete-sort");

    if (req.headers.authorization == null)
        return res.status(401).send("Missing auth token");
    if (!req.query.key)
        return res.status(400).send("Missing key in query");

    const token = req.headers.authorization.toString().split(" ")[1];
    jwt.verify(token, process.env.SECRET, (err, verified_jwt) => {
        if (err)
            return res.status(401).send(err.message);

        incomplete_db.get(`SELECT * FROM Incomplete WHERE Key = ?`, [req.query.key], function (err, item) {
            if (err)
                return res.status(500).send(err.message);
            if (item) {
                console.log(item)
                return res.send(item);
            } else
                return res.status(400).send("Incomplete sort not found");
        });
    });
});

app.post('/add-comparison', (req, res) => {
    console.log("\n/add-comparison");

    if (!req.body.key)
        return res.status(422).send("Missing key");
    if (!req.headers.authorization)
        return res.status(401).send("Missing auth token");

    const token = req.headers.authorization.toString().split(" ")[1];
    jwt.verify(token, process.env.SECRET, (err, verified_jwt) => {
        if (err)
            return res.status(401).send(err.message);

        const newValue = req.body.value === "true" ? true : false;

        incomplete_db.get(`SELECT Comparisons FROM Incomplete WHERE Key = ?`, [req.body.key], function (err, row) {
            if (err) {
                return res.status(500).send(err.message);
            } else {
                let existingData = [];
                if (row.Comparisons) {
                    try {
                        existingData = JSON.parse(row.Comparisons);
                        if (!Array.isArray(existingData)) {
                            existingData = [];
                        }
                    } catch (parseError) {
                        existingData = [];
                    }
                }
                // if there are more comparisons on the server than the requesting session, ask it to sync to the server
                if (existingData.length > req.body.size)
                    return res.status(422).send("Unable to add comparison; this sorting session is behind the database");

                existingData.push(newValue);

                incomplete_db.run(`UPDATE Incomplete SET Comparisons = ? WHERE Key = ?`, [JSON.stringify(existingData), req.body.key], function (err) {
                    if (err)
                        return res.status(500).send(err.message);
                    return res.send("Saved");
                });
            }
        });
    });
});

app.get('/all-incomplete-sorts', (req, res) => {
    console.log("\n/all-incomplete-sorts");

    if (req.headers.authorization == null)
        return res.status(401).send("Missing auth token");

    const token = req.headers.authorization.toString().split(" ")[1];
    jwt.verify(token, process.env.SECRET, (err, verified_jwt) => {
        if (err)
            return res.status(401).send(err.message);
        incomplete_db.all(`SELECT * FROM Incomplete WHERE User = ?`, [verified_jwt.body.email], function (err, rows) {
            if (err)
                return res.status(500).send(err.message);
            res.send(JSON.stringify(rows));
        });
    });
});

app.post('/add-completed-sort', (req, res) => {
    console.log("\n/add-completed-sort");

    if (req.headers.authorization == null)
        return res.status(401).send("Missing auth token");

    const token = req.headers.authorization.toString().split(" ")[1];
    jwt.verify(token, process.env.SECRET, (err, verified_jwt) => {
        if (err)
            return res.status(401).send(err.message);
        complete_db.run(`INSERT INTO Complete(Date, Songs, User) VALUES (?, ?, ?)`, [Date.now(), req.body.songs, verified_jwt.body.email], function (err) {
            if (err) {
                return res.status(500).send(err.message);
            }
            else {
                // delete respective incompleted sort (remove all incompletes of this User)
                incomplete_db.run(`DELETE FROM Incomplete WHERE User = ?`, [verified_jwt.body.email], function (err) {
                    if (err)
                        return res.status(500).send(err.message);
                    return res.send("Added sort to database");
                });
            }
        });
    });
});
