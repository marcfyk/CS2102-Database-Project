const util = require('../util/fn_utils');
const express = require('express');
const router = express.Router();
const pool = util.getPool();

router.get('/', (req, res, next) => {
  util.render(res, 'login', 'Login');
});

router.post('/', (req, res, next) => {
  const user = req.body.username;
  const pass = req.body.password;

  if (!user || !pass) {
    util.render(res, 'login', 'Login', {
      message: 'Please fill in all fields.'
    });
    return;
  }

  const query = `SELECT 1 FROM Account
      WHERE username='${user}' AND password='${pass}'`;
  pool.query(query, (err, data) => {
    if (err) {
      util.render(res, 'login', 'Login', {
        message: 'SQL error occured.' // TODO proper error message
      });
    } else {
      res.redirect('/');
    }
  });

});

module.exports = router;
