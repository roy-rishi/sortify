const sqlite3 = require('sqlite3').verbose();

let db = new sqlite3.Database("./db/main.db");

// db.run(`CREATE TABLE Users(
//     Email TEXT NOT NULL PRIMARY KEY,
//     Password TEXT NOT NULL,
//     Name TEXT
// );`);

// db.run(`INSERT INTO Users(Email, Password) VALUES(?, ?)`, ["rishiroy@gmail.com", "egbdf"]);

// db.all(`SELECT * FROM Users`, [], (err, rows) => {
//   if (err) {
//     throw err;
//   }
//   rows.forEach((row) => {
//     console.log(row.Email);
//   });
// });

db.get(`SELECT * FROM Users where Email = ?`, ["contactrishiroy@gmail.com"], (err, row) => {
    if (err)
        return console.error(err.message);
    return row ? console.log(row.Email, row.Password) : console.log("Not found");
});


db.close();