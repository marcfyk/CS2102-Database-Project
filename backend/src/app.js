// npm packages
const express = require('express')
const bodyParser = require('body-parser')

// local module exports
const mountRoutes = require('./routes/index')

// port
const PORT = process.env.PORT || 3000

// init express app
const app = express()
// set up body parser middleware to parse data
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))

// mounts all the routes to the app
mountRoutes(app)

// if all routes not caught -> app sends 404
app.use((req, res, next) => {
  res.sendStatus(404)
})

app.use((err, req, res, next) => {
  res.sendStatus(500)
})

app.listen(PORT, () => console.log(`listening on port ${PORT}`))