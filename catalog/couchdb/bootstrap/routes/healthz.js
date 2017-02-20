/* eslint no-console: 0 */
'use strict';
exports.routes = function(app, config, logger) {
  const state = {
    ok: false
  };

  app.get('/healthz', (req, res) => {
    res.status(state.ok ? 200 : 449)  // Retry with
       .json({ok:state.ok})
       .end();
  });

  app.put('/healthz/:ok', (req, res) => {
    state.ok = req.params.ok === 'true';
    res.status(204).end();
  });
}
