const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const jwt = require('njwt')

const app = express();
const PORT = 3004;

// auth middleware
function authentication(req, res, next) {
    const auth_header = req.headers.authorization;
    console.log(req.headers);

    if (!auth_header) {
        let err = new Error("unauthenticated request!");
        res.setHeader("WWW-Authenticate", "Basic");
        err.status = 401;
        return next(err);
    }

    const auth = new Buffer.from (auth_header.split(" ")[1], "base64").toString().split(":");
    const user = auth[0];
    const pass = auth[1];

    if (user == "rishi" && pass == "nom") {
        // authorization success
        console.log("authorization succeeded");
        next();
    } else {
        let err = new Error("unauthenticated request!");
        res.setHeader("WWW-Authenticate", "Basic");
        err.status = 401;
        return next(err);
    }
}
app.use(authentication);
app.use(express.static(path.join(__dirname, 'public')));

app.use(bodyParser.json());

// open db
// let db = new sqlite3.Database("./db/users.db", sqlite3.OPEN_READWRITE, (err) => {
//     if (err) {
//         console.error(err.message);
//     } else {
//         console.log("connected to database: users");
//     }
// });

// db.close();

// validate authorization request, provide token
app.get('/auth', (req, res) => {
    console.log('\nauthorizing client ');
    res.send({"auth-token": "lskjdf"});
});

app.listen((PORT), () => {
    console.log(`server is running on port ${PORT}`);
})