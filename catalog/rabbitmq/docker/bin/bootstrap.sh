#!/bin/bash
set +e

export RABBITMQ_NODENAME="rabbit@$(hostname -f)"
export RABBITMQ_USE_LONGNAME=true
export HOSTNAME=$(hostname -f)
rabbitmqctl cluster_status

FULL_NODE_NAME=$(hostname -f)
NODE_NAME=$(hostname -s)   # rabbitmq-1
DOMAIN=$(hostname -d) # default.svc.cluster.local

RABBIT_USER=rabbit

if [[ ${NODE_NAME} =~ (.*)-([0-9]+)$ ]]; then
    CLUSTER_NAME=${BASH_REMATCH[1]}
    ORD=${BASH_REMATCH[2]}
else
  printf "Failed to extract ordinal from hostname ${NODE_NAME}\n"
  exit 1
fi
MASTER_NODE="${RABBIT_USER}@${CLUSTER_NAME}-0.${DOMAIN}"

printf "Bootstraping...\n"
printf "\tMaster node: ${MASTER_NODE}\n"

function is_registered_with_master_node() {
  COUNT=$(rabbitmqctl cluster_status | grep ${MASTER_NODE} | wc -l)
  if [ "${COUNT}" == "4" ] ; then
    REGISTERED=yes
  else
    REGISTERED=no
  fi
}

function register_node() {
  rabbitmqctl stop_app
  rabbitmqctl join_cluster ${MASTER_NODE}
  rabbitmqctl start_app
}

if [ ${ORD} == "0" ] ; then
  printf "\tIs master node: YES!\n"
else
  is_registered_with_master_node
  if [ "${REGISTERED}" == "no" ] ; then
    printf "\tRegistering ${NODE_NAME} with master node."
  fi
  while [ "${REGISTERED}" == "no" ] ; do
    printf "."
    register_node
    is_registered_with_master_node
    if [ "${REGISTERED}" == "no" ] ; then
      sleep 5
    fi
  done
  printf "\n"
  printf "\t${NODE_NAME}: registered with the master node\n"
fi



# Cluster status of node 'rabbit@rabbitmq-1.rabbitmq.default.svc.cluster.local' ...
# [{nodes,[{disc,['rabbit@rabbitmq-1.rabbitmq.default.svc.cluster.local']}]},
#  {running_nodes,['rabbit@rabbitmq-1.rabbitmq.default.svc.cluster.local']},
#  {cluster_name,<<"rabbit@rabbitmq-1.rabbitmq">>},
#  {partitions,[]},
#  {alarms,[{'rabbit@rabbitmq-1.rabbitmq.default.svc.cluster.local',[]}]}]


#  [{nodes,[{disc,['rabbit@rabbitmq-0.rabbitmq.default.svc.cluster.local',
#                 'rabbit@rabbitmq-1.rabbitmq.default.svc.cluster.local']}]},
#  {running_nodes,['rabbit@rabbitmq-0.rabbitmq.default.svc.cluster.local',
#                  'rabbit@rabbitmq-1.rabbitmq.default.svc.cluster.local']},
#  {cluster_name,<<"rabbit@rabbitmq-0.rabbitmq.default.svc.cluster.local">>},
#  {partitions,[]},
#  {alarms,[{'rabbit@rabbitmq-0.rabbitmq.default.svc.cluster.local',[]},
#           {'rabbit@rabbitmq-1.rabbitmq.default.svc.cluster.local',[]}]}]

