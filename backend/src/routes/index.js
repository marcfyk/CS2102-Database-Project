// routes
const auth = require('./auth')
const user = require('./user')

module.exports = app => {
  app.use(auth)
  app.use(user)
}