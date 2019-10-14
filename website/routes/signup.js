const util = require('../util/aux')
const express = require('express');
const router = express.Router();

const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

router.get('/', (req, res, next) => {
  util.render(res, 'signup', 'Sign Up');
});

router.post('/', (req, res, next) => {
  const user = req.body.username;
  const pass = req.body.password;
  const email = req.body.email;

  if (!user || !pass || !email) {
    util.render(res, 'signup', 'Sign Up', {
      isEmpty: true
    });
  } else {
    const query = `INSERT INTO Account(username, password, email) VALUES
        ('${user}', '${pass}', '${email}')`;

    pool.query(query, (err, data) => {
      if (err) {
        util.render(res, 'signup', 'Sign Uo', {
          usernameExists: true
        });
      } else {
        res.redirect('/');
      }
    });
  }
});

module.exports = router;
