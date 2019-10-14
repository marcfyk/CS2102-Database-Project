var express = require('express');
var router = express.Router();

const { Pool } = require('pg')
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

router.get('/', function(req, res, next) {
  res.render('login', {
    pageTitle: "Log In",
    description: "desc-placeholder-login.js"
  });
});

router.post('/', function(req, res, next) {
  const user = req.body.username;
  const pass = req.body.password;
  console.log("entered");

  if (!user || !pass) {
    res.render('login', {
      pageTitle: "Log In",
      description: "desc-placeholder-login.js",
      isEmpty: true
    });

  } else {

    const query = `SELECT 1 FROM Account WHERE username='${user}' AND password='${pass}'`;
    pool.query(query, (err, data) => {
      if (err) {
        res.redirect('/login');
      } else {
        res.redirect('/');
      }
    });

  }
});

module.exports = router;
