KOPS_STATE_STORE?=s3://kubernetes-kops
KOPS_CLUSTER_NAME?=k8s.domain.com
KOPS_DNS_ZONE?=k8s.domain.com
KOPS_MASTER_ZONE?=us-east-1a
KOPS_MASTER_NODES?=3
KOPS_MASTER_INSTANCE_TYPE?=t2.micro
KOPS_MINION_ZONE?=us-east-1a
KOPS_MINION_NODES?=3
KOPS_MINION_INSTANCE_TYPE?=t2.medium


all-minikube: install-minikube minikube install-minikube-dashboard namespaces elk-minikube couchdb-minikube-all rabbitmq-all-minikube jenkins-minikube

info:
	minikube ip

dashboards: elk-kibana-dashboard elk-cerebro-dashboard couchdb-dashboard rabbitmq-dashboard jenkins-dashboard
	minikube dashboard

install-minikube:
	which kubectl  || brew install kubectl
	which minikube || brew cask install minikube

minikube:
	minikube start --cpus 4 --disk-size 40g --memory 6144
	/bin/sh -c 'kubectl get pod --all-namespaces ; CODE=$$? ; while [ $${CODE} != 0 ] ; do sleep 1 ; kubectl get pod --all-namespaces ; CODE=$$? ; done'
	kubectl create -f storage-class/minikube-storage-class.yaml

install-minikube-dashboard:
	kubectl create -f catalog/heapster/kubernetes

namespaces:
	kubectl create -f namespace/
	
	kubectl create -f storage-class/minikube-storage-class.yaml

elk-aws: elk-elasticsearch-aws elk-elasticsearch elk-logstash elk-kibana elk-kibana-aws elk-cerebro elk-cerebro-aws
elk-minikube: elk-elasticsearch-minikube elk-elasticsearch elk-logstash elk-kibana elk-kibana-minikube elk-cerebro elk-cerebro-minikube

elk-elasticsearch:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-discovery-svc.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-data-statefulset.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-master-statefulset.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-client-statefulset.yaml

elk-elasticsearch-minikube:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-svc.minikube.yaml
elk-elasticsearch-aws:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-svc.aws.yaml


elk-logstash:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/filebeat-container-configmap.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/filebeat-log-configmap.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/logstash-configmap.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/logstash-service.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/logstash-deployment.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/filebeat-container-daemonset.minikube.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/filebeat-log-daemonset.yaml

elk-kibana:
	kubectl create --namespace system-diagnostic -f secret-templates/kibana-oauth-google-secret.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kibana/kibana-oauth-google-configmap.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kibana/kibana-deployment.yaml

elk-kibana-minikube:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kibana/kibana-oauth-service.minikube.yaml
elk-kibana-aws:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kibana/kibana-oauth-service.aws.yaml

elk-kibana-dashboard:
	minikube service kibana --namespace system-diagnostic

elk-cerebro:
	kubectl create --namespace system-diagnostic -f secret-templates/cerebro-oauth-google-secret.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/cerebro/cerebro-configmap.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/cerebro/cerebro-deployment.yaml

elk-cerebro-minikube:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/cerebro/cerebro-service.minikube.yaml
elk-cerebro-aws:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/cerebro/cerebro-service.aws.yaml


elk-kopf:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kopf/kopf-service.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kopf/kopf-deployment.yaml

elk-kopf-dashboard:
	kubectl port-forward $$(kubectl get pod --namespace system-diagnostic | grep kopf | awk '{print $$1}' | head -1) 8080 --namespace system-diagnostic >& /dev/null &
	open http://localhost:8080/kopf/

elk-cerebro-dashboard:
	minikube service cerebro --namespace system-diagnostic

couchdb-minikube-all: couchdb couchdb-minikube couchdb-public-lb couchdb-public-lb-minikube
couchdb-aws-all: couchdb couchdb-aws

couchdb:
	kubectl create --namespace database -f secret-templates/couchdb-secrets.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/couchdb-discovery-service.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/couchdb-configmap.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/couchdb-statefulset.yaml
	# kubectl create --namespace database -f catalog/couchdb/kubernetes/curator/

couchdb-minikube:
	kubectl create --namespace database -f catalog/couchdb/kubernetes/couchdb-service.minikube.yaml
couchdb-aws:
	kubectl create --namespace database -f catalog/couchdb/kubernetes/couchdb-service.aws.yaml

couchdb-scale:
	kubectl scale  --namespace database --replicas=3 statefulset/couchdb

couchdb-public-lb:
	kubectl create --namespace database -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-configmap.base.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-deployment.base.yaml

couchdb-public-lb-minikube:
	kubectl create --namespace database -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-service.minikube.yaml
couchdb-public-lb-aws:
	kubectl create --namespace database -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-service.aws.yaml

couchdb-dashboard:
	open $$(minikube service couchdb-cluster --namespace database --url)/_utils

rabbitmq-all-minikube: rabbitmq rabbitmq-minikube
rabbitmq-all-aws: rabbitmq rabbitmq-aws

rabbitmq:
	kubectl create --namespace message-bus -f secret-templates/rabbitmq-secret.yaml
	kubectl create --namespace message-bus -f catalog/rabbitmq/kubernetes/rabbitmq-discovery-service.yaml
	kubectl create --namespace message-bus -f catalog/rabbitmq/kubernetes/rabbitmq-service.yaml
	kubectl create --namespace message-bus -f catalog/rabbitmq/kubernetes/rabbitmq-statefulset.yaml

rabbitmq-minikube:
	kubectl create --namespace message-bus -f catalog/rabbitmq/kubernetes/rabbitmq-service.minikube.yaml
rabbitmq-aws:
	kubectl create --namespace message-bus -f catalog/rabbitmq/kubernetes/rabbitmq-service.aws.yaml


rabbitmq-scale:
	kubectl scale  --namespace message-bus --replicas=3 statefulset/rabbitmq

rabbitmq-dashboard:
	open $$(minikube service rabbitmq-cluster --namespace message-bus --url | grep ':31672')

jenkins-minikube: jenkins
	kubectl create --namespace continuous-integration -f catalog/jenkins/kubernetes/jenkins-service.minikube.yaml

jenkins-aws: jenkins
	kubectl create --namespace continuous-integration -f catalog/jenkins/kubernetes/jenkins-service.aws.yaml

jenkins:
	kubectl create --namespace continuous-integration -f secret-templates/jenkins-secret.yaml
	kubectl create --namespace continuous-integration -f catalog/jenkins/kubernetes/jenkins-discovery-service.yaml
	kubectl create --namespace continuous-integration -f catalog/jenkins/kubernetes/jenkins-master-pvc.yaml
	kubectl create --namespace continuous-integration -f catalog/jenkins/kubernetes/jenkins-deployment.yaml

jenkins-dashboard:
	minikube service jenkins-cluster --namespace continuous-integration
	kubectl logs $$(kubectl get pods --namespace continuous-integration --output=jsonpath={.items..metadata.name}) --namespace continuous-integration

#################################################

all-aws: install-kops kops-create-cluster storage-class-aws install-aws-dashboard namespaces

all-aws-dashboard: aws-dashboard

install-kops:
	which kops     || brew install kops
	which kubectl  || brew install kubectl

kops-create-cluster:
	kops create cluster \
    --channel stable \
    --cloud aws \
    --dns-zone ${KOPS_DNS_ZONE} \
    --zones ${KOPS_MINION_ZONE} \
    --master-zones ${KOPS_MASTER_ZONE} \
    --master-count ${KOPS_MASTER_NODES} \
    --node-count ${KOPS_MINION_NODES} \
    --node-size ${KOPS_MINION_INSTANCE_TYPE} \
    --master-size ${KOPS_MASTER_INSTANCE_TYPE} \
    --ssh-public-key ${HOME}/.ssh/id_rsa.pub \
    --topology private --bastion \
    --networking weave \
    ${KOPS_CLUSTER_NAME}
	kops update cluster --name ${KOPS_CLUSTER_NAME} --yes
	
storage-class-aws:
	kubectl create -f storage-class/aws-ebs-ssd-encrypted-storage-class.yaml

install-aws-dashboard:
	kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.5.0.yaml
	kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/monitoring-standalone/v1.2.0.yaml

aws-dashboard:
	kops get secrets kube --type secret -oplaintext
	open https://api.${KOPS_DNS_ZONE}/ui

