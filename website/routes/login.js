const util = require('../util/fn_utils');
const express = require('express');
const router = express.Router();
const pool = util.getPool();

router.get('/', function(req, res, next) {
  util.render(res, 'login', 'Login');
});

router.post('/', function(req, res, next) {
  const user = req.body.username;
  const pass = req.body.password;

  if (!user || !pass) {
    util.render(res, 'login', 'Login', { isEmpty: true });
    return;
  }

  const query = `SELECT 1 FROM Account
      WHERE username='${user}' AND password='${pass}'`;
  pool.query(query, (err, data) => {
    if (err) {
      res.redirect('/login');
    } else {
      res.redirect('/');
    }
  });

});

module.exports = router;
