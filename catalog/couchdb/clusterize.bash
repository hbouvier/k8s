#!/bin/bash
set +e

OPTIONS=-v

function cluster_wait_for_node_to_be_up() {
  IP=$1
  STATUS=1
  while [ ${STATUS} != 0 ] ; do
    curl "http://${IP}:5984/_up" --fail -vu "${COUCHDB_USER}:${COUCHDB_PASSWORD}"
    STATUS=$?
    if [ ${STATUS} != 0 ] ; then
      curl "http://${IP}:5984/_up" --fail -v
      STATUS=$?
      if [ ${STATUS} != 0 ] ; then
        sleep 1
      fi
    fi
  done
}

function cluster_is_configured() {
  IP=$1
  RESULT=$(curl http://${IP}:5984/_all_dbs --fail -vu "${COUCHDB_USER}:${COUCHDB_PASSWORD}")
  STATUS=$?
  if [ ${STATUS} == 0 ] ; then
    if [ "${RESULT}" == "[]" ] ; then
      IS_CONFIGURED=false
    else
      IS_CONFIGURED=true
    fi
  else
    IS_CONFIGURED=false
  fi
  echo "[CLUSTER] IS-CONFIGURE == ${IS_CONFIGURED}"
}

function cluster_create_admin_user() {
  IP=$1
  USER=$2
  PASSWORD=$3
  SERVICE=$4

  RESULT=$(curl -XPUT "http://${IP}:5984/_node/${SERVICE}@${IP}/_config/admins/${USER}" \
    -d '"'${PASSWORD}'"' \
    --fail ${OPTIONS})
  echo "[CLUSTER-${IP}] CREATE ADMIN USER ${RESULT}"
}

function cluster_enable_http() {
  IP=$1
  SERVICE=$2

  RESULT=$(curl -XPUT "http://${IP}:5984/_node/${SERVICE}@${IP}/_config/chttpd/bind_address" \
    -d '"0.0.0.0"' \
    --fail ${OPTIONS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}")
  echo "[CLUSTER-${IP}] HTTP ENABLED == ${RESULT}"   
}


function cluster_configure_node() {
  REMOTE_NODE_IP=$1
  REMOTE_NODE_NAME=$2

  RESULT=$(curl -XPOST "http://${REMOTE_NODE_IP}:5984/_cluster_setup" \
    -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "'${COUCHDB_USER}'", "password":"'${COUCHDB_PASSWORD}'", "port": 5984, "remote_node": "'${REMOTE_NODE_IP}'", "remote_current_user": "'${COUCHDB_USER}'", "remote_current_password": "'${COUCHDB_PASSWORD}'" }' \
    -H "Content-Type: application/json" --fail ${OPTIONS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}")
  echo "[CLUSTER-${REMOTE_NODE_IP}] CONFIGURE NODE == ${RESULT}"   
}

function cluster_add_node() {
  MASTER_NODE_IP=$1
  REMOTE_NODE_IP=$2
  REMOTE_NODE_NAME=$3

  RESULT=$(curl -XPOST "http://${MASTER_NODE_IP}:5984/_cluster_setup" \
    -d '{"action": "add_node", "host":"'${REMOTE_NODE_IP}'", "port": "5984", "username": "'${COUCHDB_USER}'", "password":"'${COUCHDB_PASSWORD}'"}' \
    -H "Content-Type: application/json" --fail ${OPTIONS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}")
  echo "[CLUSTER-${REMOTE_NODE_IP}] ADD NODE == ${RESULT}"   
}
function node_add_node() {
  REMOTE_NODE_IP=$1
  SERVICE=$2

  RESULT=$(curl -XPUT "http://127.0.0.1:5986/_nodes/${SERVICE}@${REMOTE_NODE_IP}" \
    -d '{}' \
    -H "Content-Type: application/json" --fail ${OPTIONS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}")
  echo "[CLUSTER-${REMOTE_NODE_IP}] ADD NODE == ${RESULT}"   
}

function cluster_finished() {
  IP=$1
  RESULT=$(curl -XPOST "http://${IP}:5984/_cluster_setup" \
    -d '{"action": "finish_cluster"}' \
    -H "Content-Type: application/json" --fail ${OPTIONS} -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}")
  echo "[CLUSTER-${IP}] FINISHED == ${RESULT}"   
}

function cluster_membership() {
  IP=$1
  RESULT=$(curl http://${IP}:5984/_membership -su "${COUCHDB_USER}:${COUCHDB_PASSWORD}")
  echo "[CLUSTER-${IP}] MEMBERSHIP == ${RESULT}"   
}

NODE_IP=$(hostname -f)
NODE_NAME=$(hostname -s)   # couchdb-0
DOMAIN=$(hostname -d) # default.svc.cluster.local

if [[ ${NODE_NAME} =~ (.*)-([0-9]+)$ ]]; then
    CLUSTER_NAME=${BASH_REMATCH[1]}
    ORD=${BASH_REMATCH[2]}
else
  echo "Failed to extract ordinal from hostname ${NODE_NAME}"
  exit 1
fi

MASTER_NODE_NAME="${CLUSTER_NAME}-0"
MASTER_NODE_IP="${MASTER_NODE_NAME}.${DOMAIN}"

echo "===================== Waiting for this node to be ready ========================"
cluster_wait_for_node_to_be_up ${NODE_IP}

echo "================= Verifying if this node is already configured ====================="
cluster_is_configured ${NODE_IP}

if [ "${IS_CONFIGURED}" == "false" ] ; then 

  echo "=============================== SETUP NODE ===================================="

  if [ "${MASTER_NODE_NAME}" != "${NODE_NAME}" ] ; then
    echo "===================== Waiting for this Master node to be ready ========================"
    cluster_wait_for_node_to_be_up ${MASTER_NODE_IP}
    IS_CONFIGURED=false
    while [ "${IS_CONFIGURED}" == "false" ] ; do
      cluster_is_configured ${MASTER_NODE_IP}
      sleep 1
    done
  fi

  echo "============ Adding node ${CLUSTER_NAME}@${NODE_IP} to the cluster ==============="

  cluster_create_admin_user "${NODE_IP}" "${COUCHDB_USER}" "${COUCHDB_PASSWORD}" "${CLUSTER_NAME}"
  cluster_enable_http "${NODE_IP}" "${CLUSTER_NAME}"

  cluster_configure_node "${NODE_IP}" "${NODE_NAME}"
  echo "[CLUSTER] REMOTE-NODE=${NODE_IP} MASTER_NODE=${MASTER_NODE_IP}"
  if [ "${MASTER_NODE_IP}" != "${NODE_IP}" ] ; then
    echo "[CLUSTER] ADDING ${NODE_IP}"
    # cluster_add_node "${MASTER_NODE_IP}" "${NODE_IP}" "${NODE_NAME}"
    node_add_node "${MASTER_NODE_IP}" "${CLUSTER_NAME}"
  else
    echo "======================= Finishing cluster configuration =========================="
    echo "[CLUSTER] finishing ${MASTER_NODE_IP}"
    cluster_finished "${MASTER_NODE_IP}"
  fi
fi
echo "========================= Cluster configured and ready ==========================="
cluster_membership 127.0.0.1

