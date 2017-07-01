/* eslint no-console: 0 */
'use strict';
const { proxy } = require('mirv');
exports.routes = function(app, config, logger) {
  const state = {
    ok:      false
  };

  const auth = proxy.basic_auth(config.couchdb.username, config.couchdb.password);

  app.get('/_ready', (req, res) => {
    res.status(204).end();
  });

  app.get('/_up', (req, res) => {
    is_couchdb_configured()
      .then(ok =>  is_couchdb_healthy('http://127.0.0.1:5984/_up'))
      .then(ok =>  res.status(200).json({ok: true}).end())
      .catch(err => res.status(449).json({ok: false, message: err.message || ''}).end());
  });

  app.get('/healthz', (req, res) => {
    res.status(state.ok ? 200:449).json({ok: state.ok}).end();
  });

  app.put('/healthz/:ok', (req, res) => {
    state.ok = req.params.ok === 'true';
    res.status(204).end();
  });

  function is_couchdb_configured() {
    return state.ok ? Promise.resolve(true) : Promise.reject(new Error('CouchDB cluster not configured.'));
  }

  function is_couchdb_healthy(url) {
    return proxy.get(url, auth)
      .then(body => json(body))
      .then(response => {
        if (response.status !== 'ok') throw new Error(`GET /_up response === '${JSON.stringify(response)}'`);
        return true;
      });
  }

  function json(buffer) {
    try {
      const obj = JSON.parse(buffer);
      return Promise.resolve(obj);
    } catch (err) {
      return Promise.reject(err);
    }
  }
};
