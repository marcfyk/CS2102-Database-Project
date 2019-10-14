const MINIMUM_PASSWORD_LEN = 8;

module.exports = {
  // for easy rendering of view
  render : (res, route, title, props = {}) => {
    local = {
      pageTitle: title
    }
    Object.keys(props).forEach(key => {
      local[key] = props[key];
    });
    res.render(route, local);
  },

  // to get pool, using dotenv
  getPool : () => {
    const { Pool } = require('pg');
    return new Pool({ connectionString: process.env.DATABASE_URL })
  },

  isGoodPassword : (pass) => {
    return String(pass).length >= MINIMUM_PASSWORD_LEN;
  },

  // does not contain spaces
  isGoodUsername : (username) => {
    return !/\s/.test(String(username).trim());
  }
};
