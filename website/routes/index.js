var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) {
  res.render('index', {
    pageTitle: "Home",
    description: "desc-placeholder-index.js"
  });
});

module.exports = router;
