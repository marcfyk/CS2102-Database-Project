const bcrypt = require('bcrypt')
const bcryptConfig = require('../configs/bcrypt-config')

module.exports = {
  hashPassword: async plainTextPassword => {
    return await bcrypt.hash(plainTextPassword, bcryptConfig.saltRounds)
  },
  validatePassword: async (plainTextPassword, hash) => {
    return await bcrypt.compare(plainTextPassword, hash)
  }
}