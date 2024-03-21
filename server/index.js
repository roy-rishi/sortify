const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('njwt');
require('dotenv').config();
var nodemailer = require('nodemailer');
const bcrypt = require("bcrypt")

const app = express();
const PORT = 3004;

function createJWT(user, expiration_mins) {
    // add identifying information
    const claims = { email: user };
    const token = jwt.create(claims, process.env.SECRET);
    token.setExpiration(new Date().getTime() + (expiration_mins * 60 * 1000));
    return token.compact();
}


// open db
let db = new sqlite3.Database('./db/main.db');

// start server
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.listen((PORT), () => {
    console.log(`server is running on port ${PORT}`);
});

// init email service
var transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL,
        pass: process.env.PASS
    }
});

// validate login request, provide jwt token
app.get('/login', (req, res) => {
    console.log("\n/login");

    // parse authentication header
    const auth_header = req.headers.authorization;
    if (!auth_header) {
        res.setHeader("WWW-Authenticate", "Basic");
        return res.status(401).send("unauthorized request");
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
                    console.log("authorization successful");
                    res.send(createJWT(user, 2));
                } else
                    return res.status(401).send("Invalid password");
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
    // create jwt with their email and 15 minute expiration
    const access_token = createJWT(email, 15);

    var mailOptions = {
        from: process.env.EMAIL,
        to: email,
        subject: "Verify Your Email to Use Sortify",
        html: `<h2>Please enter this access code in the Sortify application</h2><p>For your security, we do not provide a direct link.</p><b>${access_token}</b>\n<p>If you did not request to sign up, please disregard this email.</p>`
    };

    transporter.sendMail(mailOptions, function (error, info) {
        if (error) {
            if (error.toString().includes("Error: No recipients defined"))
                return res.status(422).send("Likely failed due to invalid email address");
            else
                return res.status(500).send(error);
        } else {
            console.log("sent confirmation email", info.response);
            res.send("Confirmation email sent");
        }
    });
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

    const token = req.headers.authorization.toString().split(" ")[1];
    jwt.verify(token, process.env.SECRET, (err, verified_jwt) => {
        console.log(err ? err.message : "verified jwt");
        res.send(err ? err.message : "verified!");
    });
});
