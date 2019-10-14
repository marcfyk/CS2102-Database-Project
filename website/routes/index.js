const util = require('../util/fn_utils')
const express = require('express');
const router = express.Router();

router.get('/', (req, res, next) => {
  util.render(res, 'index', 'Home');
});

module.exports = router;
