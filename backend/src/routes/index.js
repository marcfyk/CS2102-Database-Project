// routes
const account = require('./account')
const user = require('./user')

module.exports = app => {
  app.use(account)
  app.use(user)
}