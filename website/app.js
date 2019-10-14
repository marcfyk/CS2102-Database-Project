var createError = require('http-errors');
var express = require('express');
var expressLayouts = require('express-ejs-layouts');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var bodyParser = require('body-parser');
var favicon = require('serve-favicon');

require('dotenv').config();

// ==== routers ===========================================================
// = add routers here
// ========================================================================
var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');
var sqlRouter = require('./routes/sql');
var loginRouter = require('./routes/login');
var signUpRouter = require('./routes/signup');

var app = express();

// ==== view engine setup =================================================
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, '/public')));
app.use(expressLayouts);
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(favicon(path.join(__dirname, 'public/images', 'favicon.ico')))

// ==== routes -===========================================================
// = add routes here after adding the routers above ^^^
// ========================================================================
app.use('/', indexRouter);
app.use('/users', usersRouter);
app.use('/sql', sqlRouter);
app.use('/login', loginRouter);
app.use('/signup', signUpRouter);

// ==== error handling ====================================================
app.use(function(req, res, next) {
  next(createError(404));
});
app.use(function(err, req, res, next) {
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};
  res.locals.pageTitle = "asdf";
  res.locals.scripts = "<script></script>";
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;
