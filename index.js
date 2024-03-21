const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const jwt = require('njwt');
require('dotenv').config();
var nodemailer = require('nodemailer');

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
        let err = new Error("unauthenticated request!");
        res.setHeader("WWW-Authenticate", "Basic");
        err.status = 401;
        return next(err);
    }
    const auth = new Buffer.from(auth_header.split(" ")[1], "base64").toString().split(":");
    const user = auth[0];
    const pass = auth[1];

    // validate authentication values
    if (user == "rishi" && pass == "nom") {
        // authorization success
        console.log("authorization successful");
        res.send(createJWT(user, 2));
    } else {
        let err = new Error("failed to authenticate!");
        res.setHeader("WWW-Authenticate", "Basic");
        err.status = 401;
        res.send(err);
    }
});

app.post("/verify-email", (req, res) => {
    console.log("\n/verify-email");

    const email = req.body.email;
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
            console.log(error);
        } else {
            console.log("sent confirmation email", info.response);
            res.send("confirmation email sent");
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
