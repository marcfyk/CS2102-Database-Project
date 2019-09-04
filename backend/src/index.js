const express = require('express')
const bodyParser = require('body-parser')
const PORT = process.env.PORT || 3000

const app = express()

app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))

app.use((req, res, next) => {
  res.sendStatus(404)
})

app.use((err, req, res, next) => {
  res.sendStatus(500)
})

app.listen(PORT, () => console.log(`listening on port ${PORT}`))