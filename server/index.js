const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('njwt');
require('dotenv').config();
const bcrypt = require("bcrypt")
const { exec } = require('child_process');

const app = express();
const PORT = 3004;

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
let db = new sqlite3.Database('./db/main.db');

// start server
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.listen((PORT), () => {
    console.log(`server is running on port ${PORT}`);
});

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
    db.get(`SELECT * FROM Users where Email = ?`, [user], (err, row) => {
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
                    res.send(createJWT(user, 2));
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
        return res.status(400).send("Unable to parse JWT");
    }
    let email = null;
    const pass = req.body.pass;
    const name = req.body.name;
    // verify jwt
    jwt.verify(jwt_token, process.env.SECRET, (err, verified_jwt) => {
        if (err)
            return res.status(401).send(err.message); // invalid jwt
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
                    db.run(query, [email, hash, name], (err) => {
                        if (err) {
                            // user already exists error
                            if (err.message.includes("SQLITE_CONSTRAINT: UNIQUE constraint failed:")) {
                                res.status(422).send("This user already exists");
                                return console.log("This user already exists!");
                            }
                            // other error
                            console.error(err.message);
                            return res.status(500).send(err.message);
                        } else
                            return res.send("created user!");
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

    db.get(`SELECT * FROM users WHERE Email = ?`, [req.body.email], (err, row) => {
        if (err)
            return res.status(500).send(err.message);
        return res.send(row ? "Email is registered" : "Email not registered");
    })
});