var express = require('express');
var router = express.Router();

const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

var sql_query = 'SELECT * FROM student_info';

router.get('/', function(req, res, next) {
  pool.query(sql_query, (err, data) => {
    res.render('sql', {
      pageTitle: "SQL example",
      data: data.rows
    });
  });
});

module.exports = router;
