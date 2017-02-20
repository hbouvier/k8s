/* eslint no-console: 0 */
'use strict';

const {parse_kubernetes_statefulset_hostname} = require('../../api/setup').setup();

describe("Couchdb Cluster Setup", () => {
  it("host parser of 'couchdb.acme.com' to fail", () => {
    const hostname = 'couchdb.acme.com';
    expect(
      () => parse_kubernetes_statefulset_hostname(hostname)
    ).toThrowError(/INVALID kubernetes statefuleset hostname FORMAT/);
  });

  it("host parser of 'couchdb-1.couchdb.default.svb.cluster.local'", () => {
    const hostname = 'couchdb-1.couchdb.default.svb.cluster.local';
    const host = parse_kubernetes_statefulset_hostname(hostname);
    expect(host.long).toBe(hostname);
    expect(host.short).toBe('couchdb-1');
    expect(host.service).toBe('couchdb');
    expect(host.instance).toBe(1);
    expect(host.domain).toBe('couchdb.default.svb.cluster.local');
  });
  it("decomposing host parser result of 'couchdb-1.couchdb.default.svb.cluster.local'", () => {
    const hostname = 'couchdb-1.couchdb.default.svb.cluster.local';
    const {
      service : cluster_name,
      domain  : domain,
      long    : couchdb_node
    } = parse_kubernetes_statefulset_hostname(hostname);
    const seed_node = `${cluster_name}-0.${domain}`;
    expect(cluster_name).toBe('couchdb');
    expect(seed_node).toBe('couchdb-0.couchdb.default.svb.cluster.local');
    expect(couchdb_node).toBe('couchdb-1.couchdb.default.svb.cluster.local');
  });



});
