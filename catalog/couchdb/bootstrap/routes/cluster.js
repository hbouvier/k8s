/* eslint no-console: 0 */
'use strict';
// const basic_auth   = require('basic-auth-connect');

exports.routes = function(app, config, logger) {
  // if (config.username && config.password) {
  //   app.use(basic_auth(config.username, config.password));
  // }
  app.get('/version', (req, res) => {
    res.json({version:1.0}).end();
  });
}
