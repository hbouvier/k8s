/* eslint no-console: 0 */
'use strict';
const { proxy } = require('mirv');

exports.cluster = function(config, state) {
  const auth = proxy.basic_auth(config.couchdb.username, config.couchdb.password);

  function _is_couchdb_up(host, auth) {
    return proxy.get(`http://${host}:5984/_up`, auth, config.debug);
  }

  function wait_for_couchdb_to_be_up(host) {
    const delay = 1000;

    return new Promise( (resolve, reject) => {
      function _wait_for_couchdb_to_be_up() {
        _is_couchdb_up(host)
          .then(body   => json(body))
          .then(res => {
            /* DEBUG */ console.log(`${host} - [  ] couchdb ==> ${JSON.stringify(res)}`);
            if (res.status === 'ok') {
              return resolve(`${host} - [ok] couchdb up ==> ${JSON.stringify(res)}`);
            }
            return setTimeout(_wait_for_couchdb_to_be_up, delay);
          })
          .catch(err => {
            /* DEBUG */ console.log(`${host} - [  ] couchdb ==> ${err.message}`);
            return setTimeout(_wait_for_couchdb_to_be_up, delay);
          });
      }
      return _wait_for_couchdb_to_be_up();
    });
  }

  function is_couchdb_cluster_enabled(host, auth) {
    return proxy.get(`http://${host}:5984/_all_dbs`, auth, config.debug)
              .then(body => {
                return json(body);
              })
              .then(list_of_databases => {
                if (list_of_databases.length > 0) {
                  return `${host} - [ok] couchdb clustering configured ==> ${JSON.stringify(list_of_databases)}`;
                }
                throw new Error(`${host} [KO] couchdb clustering configured ==> ${JSON.stringify(list_of_databases)}`);
                //return Promise.reject(new Error(`${host} [KO] couchdb clustering configured ==> ${JSON.stringify(list_of_databases)}`));
              })
              .catch(err => {
                throw new Error(`${host} [KO] couchdb clustering configured ==> ${err.message}`);
                //return Promise.reject(new Error(`${host} [KO] couchdb clustering configured ==> ${err.message}`));
              });
  }

  function create_admin_user(host, cluster_name) {
    return proxy.put(
      `http://${host}:5984/_node/${cluster_name}@${host}/_config/admins/${config.couchdb.username}`,
      `"${config.couchdb.password}"`,
      {'Content-Type': 'plain/text; charset=UTF-8'},
      config.debug
    )
    .then(body => json(body))
    .then(res => {
      return `${host} - [ok] create the 'admin' user ==> ${JSON.stringify(res)}`;
    })
    .catch(err => {
      throw new Error(`${host} [KO] create the 'admin' user ==> ${err.message}`);
      //return Promise.reject(new Error(`${host} [KO] create the 'admin' user ==> ${err.message}`));
    });
  }

  function enable_http(host, cluster_name) {
    return proxy.put(
      `http://${host}:5984/_node/${cluster_name}@${host}/_config/chttpd/bind_address`,
      `"0.0.0.0"`,
      Object.assign({},
        auth,
        {'Content-Type': 'plain/text; charset=UTF-8'}
      ),
      config.debug
    )
    .then(body => json(body))
    .then(res => {
      if (res !== 'any') throw new Error(`${host} - [KO] http server listen to 0.0.0.0 ==> ${JSON.stringify(res)}`);
      // if (res !== 'any') return Promise.reject(new Error(`${host} - [KO] http server listen to 0.0.0.0 ==> ${res}`));
      return `${host} - [ok] http server listen to 0.0.0.0 ==> ${JSON.stringify(res)}`;
    })
    .catch(err => { 
      throw new Error(`${host} - [KO] http server listen to 0.0.0.0 ==> ${err.message}`);
      //return Promise.reject(new Error(`${host} - [KO] http server listen to 0.0.0.0 ==> ${err.message}`));
    });
  }

  function enable_cluster(host) {
    return proxy.post(
      `http://${host}:5984/_cluster_setup`,
      JSON.stringify({
        action:                  'enable_cluster',
        bind_address:            '0.0.0.0',
        username:                config.couchdb.username,
        password:                config.couchdb.password,
        port:                    5984,
        remote_node:             host,
        remote_current_user:     config.couchdb.username,
        remote_current_password: config.couchdb.password
      }),
      auth,
      config.debug
    )
    .then(body => json(body))
    .then(res => {
      return `${host} - [ok] enable couchdb clustering  ==> ${JSON.stringify(res)}`;
    })
    .catch(err => { 
      throw new Error(`${host} - [KO] enable couchdb clustering ==> ${err.message}`);
      //return Promise.reject(new Error(`${host} - [KO] enable couchdb clustering ==> ${err.message}`));
    });
  }

  function cluster_configed(host) {
    return proxy.post(
      `http://${host}:5984/_cluster_setup`,
      '{"action": "finish_cluster"}',
      auth,
      config.debug
    )
    .then(res => {
      return `${host} - [ok] cluster configured  ==> ${res}`;
    })
    .catch(err => {
      try {
        const res = JSON.parse(err.message);
        if (res.code === 400){ // JSON.parse(res.body).reason == 'Cluster is already finished'
          return `${host} - [ok] cluster configured  ==> already finished`;
        }
      } catch (ex) {
        throw new Error(`${host} - [KO] cluster configured  ==> ${JSON.stringify(ex.message)}`);
      }
      throw new Error(`${host} - [KO] cluster configured  ==> ${JSON.stringify(err.message)}`);
      //return Promise.reject(new Error(`${host} - [KO] cluster configured  ==> ${JSON.stringify(err.message)}`));
    });
  }

  function add_seed_host(seed_host, cluster_name) {
    return proxy.put(`http://127.0.0.1:5986/_nodes/${cluster_name}@${seed_host}`,
      JSON.stringify({}),
      auth,
      config.debug == 'true'
    )
    .then(res => {
      return `127.0.0.1 - [ok] add ${seed_host} as seed host  ==> ${res}`;
    })
    .catch(err => {
      try {
        const res = JSON.parse(err.message);
        if (res.code === 409) {
          return `${seed_host} - [ok] add ${seed_host} as seed host  ==> already present`;
        }
      } catch (ex) {
        throw ex;
        //return Promise.reject(ex);
      }
      //return Promise.reject(new Error(`${host} - [KO] add seed host ==> ${err.message}`));
      throw new Error(`${seed_host} - [KO] add ${seed_host} as seed host ==> ${err.message}`);
    });
  }

  function list_members(host) {
    return proxy.get(
      `http://${host}:5984/_membership`,
      auth,
      config.debug
    )
    .then(body => json(body))
    .then(res => {
      return `${host} - [ok] cluster members  ==> ${JSON.stringify(res)}`;
    })
    .catch(err => {
      throw new Error(`${host} - [KO] cluster members  ==> ${JSON.stringify(err.message)}`);
      //return Promise.reject(new Error(`${host} - [KO] cluster members ==> ${JSON.stringify(err.message)}`));
    });
  }


  return {
    wait_for_couchdb_to_be_up:  wait_for_couchdb_to_be_up,
    is_couchdb_cluster_enabled: is_couchdb_cluster_enabled,
    create_admin_user:          create_admin_user,
    enable_http:                enable_http,
    enable_cluster:             enable_cluster,
    cluster_configed:           cluster_configed,
    add_seed_host:              add_seed_host,
    list_members:               list_members
  };
}

function json(buffer) {
  try {
    const obj = JSON.parse(buffer);
    return Promise.resolve(obj);
  } catch (err) {
    return Promise.reject(err);
  }
}

