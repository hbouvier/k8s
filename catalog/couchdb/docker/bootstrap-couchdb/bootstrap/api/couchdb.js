/* eslint no-console: 0 */
'use strict';
const { proxy } = require('mirv');

exports.cluster = function(config, state) {
  const auth = proxy.basic_auth(config.couchdb.username, config.couchdb.password);


  function wait_for_couchdb_to_be_up(host) {
    const delay = 1000;

    function _is_couchdb_up(host, auth) {
      return proxy.get(`http://${host}:5984/_up`, auth, config.debug);
    }

    return new Promise( (resolve, reject) => {
      function _wait_for_couchdb_to_be_up() {
        _is_couchdb_up(host, auth)
          .then(body   => json(body))
          .then(res => {
            /* DEBUG */ console.log(`${host} - [  ] couchdb ==> ${JSON.stringify(res)}`);
            if (res.status === 'ok') {
              return resolve(`${host} - [ok] couchdb up ==> ${JSON.stringify(res)}`);
            }
            return setTimeout(_wait_for_couchdb_to_be_up, delay);
          })
          .catch(err => {
            /* DEBUG */ console.log(`${host} - [  ] couchdb === ${err.message}`);
            return setTimeout(_wait_for_couchdb_to_be_up, delay);
          });
      }
      _wait_for_couchdb_to_be_up();
    });
  }

  function create_admin_user(host, cluster_name) {
    return proxy.put(
      `http://${host}:5984/_node/${cluster_name}@${host}/_config/admins/${config.couchdb.username}`,
      `"${config.couchdb.password}"`,
      Object.assign({},
        auth,
        {'Content-Type': 'plain/text; charset=UTF-8'},
      ),
      config.debug
    )
    .then(body => json(body))
    .then(res => {
      return `${host} - [ok] create the 'admin' user ==> ${JSON.stringify(res)}`;
    })
    .catch(err => {
      throw new Error(`${host} [KO] create the 'admin' user ==> ${err.message}`);
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
      return `${host} - [ok] http server listen to 0.0.0.0 ==> ${JSON.stringify(res)}`;
    })
    .catch(err => { 
      throw new Error(`${host} - [KO] http server listen to 0.0.0.0 ==> ${err.message}`);
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
      }
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
    });
  }

  function verify_cluster_configuration(cluster_name, seed_node, host) {
    return proxy.get(
        `http://${host}:5984/_membership`,
        auth,
        config.debug
      )
      .then(body => json(body))
      .then(members => {
        console.log(`${host} - [ok] ${host} server administrator configured.`);
        if (members.all_nodes.indexOf(`${cluster_name}@${host}`) < 0) throw new Error(`${host} - [KO] ${host} has been discovered.`);
        if (members.all_nodes.indexOf(`${cluster_name}@${seed_node}`) < 0) console.log(`${host} - [WARNING] ${seed_node} has NOT been discovered YET.`);
        if (members.cluster_nodes.indexOf(`${cluster_name}@${host}`) < 0) throw new Error(`${host} - [KO] ${host} is part of the cluster.`);
        if (members.cluster_nodes.indexOf(`${cluster_name}@${seed_node}`) < 0) throw new Error(`${host} - [KO] ${seed_node} is part of the cluster.`);
        return seed_node === host ? 
          `${host} - [ok] ${host} has been discovered and is part of the cluster` :
          `${host} - [ok] ${host} and ${seed_node} hve been discovered and are part of the cluster`;
      })
      .then(progress)
      .then(msg => {
        return proxy.get(
          `http://${host}:5984/_node/${cluster_name}@${host}/_config/chttpd/bind_address`,
          auth,
          config.debug
        )
        .then(value => {
          if (value.replace(/\n/, '') === '"0.0.0.0"') return `${host} - [OK] http enaled`;
          throw new Error(`${host} - [KO] http enaled`);
        });
      })
      .then(progress)
      .then(msg => {
        return proxy.get(
          `http://${host}:5984/_cluster_setup`,
          auth,
          config.debug
        )
        .then(progress)
        .then(body => json(body))
        .then(response => {
          if (response.state === 'cluster_finished') return `${host} - [OK] cluster finished`;
          throw new Error(`${host} - [KO] cluster finished`);
        })
        .then(msg => `${host} - [OK] CLUSTER VERIFIED and READY!`);
      });
  }

  function progress(msg) {
    console.log(msg);
    return msg;
  }


  return {
    wait_for_couchdb_to_be_up:    wait_for_couchdb_to_be_up,
    create_admin_user:            create_admin_user,
    enable_http:                  enable_http,
    enable_cluster:               enable_cluster,
    cluster_configed:             cluster_configed,
    add_seed_host:                add_seed_host,
    list_members:                 list_members,
    verify_cluster_configuration: verify_cluster_configuration
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

