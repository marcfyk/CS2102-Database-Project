const util = require('../util/fn_utils');
const express = require('express');
const router = express.Router();
const pool = util.getPool();

router.get('/', (req, res, next) => {
  util.render(res, 'signup', 'Sign Up');
});

router.post('/', (req, res, next) => {
  const user = req.body.username;
  const pass = req.body.password;
  const email = req.body.email;

  let warning = "";

  if (!user || !pass || !email) {
    warning.concat('Please fill in all fields.<br>');
  }
  if (!util.isGoodPassword(pass)) {
    warning.concat('Password must be at least 8 characters long.<br>');
  }
  if (!util.isGoodUsername(user) || user === "") {
    warning.concat('Username may not contain any spaces.<br>');
  }

  if (warning) {
    util.render(res, 'signup', 'Sign Up', { message: warning });
    return;
  }

  const query = 
      `INSERT INTO Account(username, password, email)
      VALUES ('${user}', '${pass}', '${email}')`;

  pool.query(query, (err, data) => {
    if (err) {
      util.render(res, 'signup', 'Sign Up', {
        message: 'SQL error occured.' // TODO proper error message
      });
    } else {
      res.redirect('/');
    }
  });

});

module.exports = router;
