/* eslint no-console: 0 */
'use strict';
const os      = require('os');

exports.setup = function (config, state) {
  const couchdb = require('./couchdb').cluster(config, state);

  function parse_kubernetes_statefulset_hostname(hostname = os.hostname()) {
    const regex_ = /^((.+)-([^.]+))\.(.+)$/;
    const captured = hostname.match(regex_);
    if (captured !== null && captured[0] !== undefined && captured.length > 0) {
      return {
        long:     captured[0],
        short:    captured[1],
        service:  captured[2],
        instance: parseInt(captured[3]),
        domain:   captured[4]
      };
    }
    throw new Error(`hostname.parse_kubernetes_statefulset_hostname(${hostname}): INVALID kubernetes statefuleset hostname FORMAT. Expected service-ordinal.domain`);
  }

  function enable_cluster(cluster_name, seed_node, couchdb_node) {
    return couchdb.create_admin_user(couchdb_node, cluster_name)
      .then(progress)
      .then(msg => couchdb.enable_http(couchdb_node, cluster_name))
      .then(progress)
      .then(msg => couchdb.enable_cluster(couchdb_node))
      .then(msg => {
        if (seed_node != couchdb_node) return msg;
        console.log(msg);
        return couchdb.cluster_configed(couchdb_node);
      })
      .then(progress)
  }

  function cluster(hostname = os.hostname()) {
    console.log(`Setting up cluster: "${hostname}"`);
    const {
      service : cluster_name,
      domain  : domain,
      long    : couchdb_node
    } = parse_kubernetes_statefulset_hostname(hostname);
    const seed_node = `${cluster_name}-0.${domain}`;

    return couchdb.wait_for_couchdb_to_be_up(couchdb_node)
    .then(progress)
    .then(msg => enable_cluster(cluster_name, seed_node, couchdb_node))
    .then(msg => {
      if (seed_node == couchdb_node) return msg;
      return couchdb.add_seed_host(seed_node, cluster_name)
        .then(process)
    })
    .then(progress)
    .then(msg => couchdb.list_members(couchdb_node))
    .then(progress)

    /*
    .then(msg => {
      return couchdb.is_couchdb_cluster_enabled(couchdb_node, {})  // no auth
        .then(progress)
        .catch(msg => couchdb.is_couchdb_cluster_enabled(couchdb_node)) // with auth
        .then(progress)
        .catch(err => {
          console.log('=============== Joining CouchDB Cluster ===============')
          return enable_cluster(cluster_name, seed_node, couchdb_node)
        })
        .then(msg => {
          if (seed_node == couchdb_node) return msg;
          return couchdb.add_seed_host(seed_node, cluster_name)
            .then(process)
        })
        .then(progress)
        .then(msg => couchdb.list_members(couchdb_node))
        .then(progress)
    });
    */
  }

  function progress(msg) {
    console.log(msg);
    return msg;
  }

  return {
    cluster: cluster,
    parse_kubernetes_statefulset_hostname: parse_kubernetes_statefulset_hostname
  };
};
