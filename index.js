const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const jwt = require('njwt')

const app = express();
const PORT = 3004;

app.use(bodyParser.json());

// open db: users
let db = new sqlite3.Database("./db/users.db", sqlite3.OPEN_CREATE, (err) => {
    if (err) {
        console.error(err.message);
    } else {
        console.log("connected to database: users");
    }
});

db.close();

// validate authorization request, provide token
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
    const auth = new Buffer.from (auth_header.split(" ")[1], "base64").toString().split(":");
    const user = auth[0];
    const pass = auth[1];

    // validate authentication values
    if (user == "rishi" && pass == "nom") {
        // authorization success
        console.log("authorization successful");
        const claims = {iss: "sortify1.0", sub:"AzureDiamond"};
        const token = jwt.create(claims, "secret-phrase");
        token.setExpiration(new Date().getTime() + (60 * 1000));
        res.send(token.compact());
    } else {
        let err = new Error("unauthenticated request!");
        res.setHeader("WWW-Authenticate", "Basic");
        err.status = 401;
        res.send(err);
    }
    // res.send({"auth-token": "lskjdf"});
});

app.get('/verify', (req, res) => {
    console.log("/verify");
    const token = req.headers.authorization.toString().split(" ")[1];
    console.log(token)
    jwt.verify(token, "secret-phrase", (err, verified_jwt) => {
        if (err) {
            res.send(err.message);
        } else {
            res.send("verified!");
        }
    })
});

app.listen((PORT), () => {
    console.log(`server is running on port ${PORT}`);
})