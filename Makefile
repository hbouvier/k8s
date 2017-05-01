PROVIDER?=minikube

all: install minikube elk couchdb-all rabbitmq-all jenkins

info:
	minikube ip

dashboards: elk-kibana-dashboard elk-cerebro-dashboard couchdb-dashboard rabbitmq-dashboard jenkins-dashboard
	minikube dashboard

upgrade:
	brew update
	brew install kubectl
	which minikube || brew cask install minikube
	brew cask reinstall minikube

install:
	which kubectl  || brew install kubectl
	which minikube || brew cask install minikube

minikube:
	minikube start --cpus 4 --disk-size 40g --memory 6144
	/bin/sh -c 'kubectl get pod --all-namespaces ; CODE=$$? ; while [ $${CODE} != 0 ] ; do sleep 1 ; kubectl get pod --all-namespaces ; CODE=$$? ; done'
	kubectl create -f namespace/
	kubectl create -f storage-class/minikube-storage-class.yaml
	kubectl create -f catalog/heapster/kubernetes
	/bin/sh -c 'minikube dashboard ; CODE=$$? ; while [ $${CODE} != 0 ] ; do sleep 1 ; minikube dashboard ; CODE=$$? ; done'
	minikube addons enable ingress
	minikube ip

elk: elk-elasticsearch elk-logstash elk-kibana elk-cerebro


elk-elasticsearch:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-discovery-svc.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-ingress.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-svc.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-data-statefulset.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-master-statefulset.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/es-client-statefulset.yaml

elk-logstash:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/filebeat-container-configmap.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/filebeat-log-configmap.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/logstash-configmap.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/logstash-ingress.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/logstash-service.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/logstash-deployment.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/filebeat-container-daemonset.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/logstash/filebeat-log-daemonset.yaml

elk-kibana:
	kubectl create --namespace system-diagnostic -f secret-templates/kibana-oauth-google-secret.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kibana/kibana-oauth-google-configmap.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kibana/kibana-ingress.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kibana/kibana-oauth-service.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kibana/kibana-deployment.yaml

elk-kibana-dashboard:
	minikube service kibana --namespace system-diagnostic

elk-cerebro:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/cerebro/cerebro-configmap.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/cerebro/cerebro-ingress.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/cerebro/cerebro-service.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/cerebro/cerebro-deployment.yaml

elk-kopf:
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kopf/kopf-ingress.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kopf/kopf-service.${PROVIDER}.yaml
	kubectl create --namespace system-diagnostic -f catalog/elk/kubernetes/kopf/kopf-deployment.yaml

elk-kopf-dashboard:
	kubectl port-forward $$(kubectl get pod --namespace system-diagnostic | grep kopf | awk '{print $$1}' | head -1) 8080 --namespace system-diagnostic >& /dev/null &
	open http://localhost:8080/kopf/

elk-cerebro-dashboard:
	minikube service cerebro --namespace system-diagnostic

couchdb-all: couchdb # couchdb-public-lb

couchdb:
	kubectl create --namespace database -f secret-templates/couchdb-secrets.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/couchdb-discovery-service.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/couchdb-configmap.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/couchdb-ingress.${PROVIDER}.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/couchdb-service.${PROVIDER}.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/couchdb-statefulset.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/curator/

couchdb-scale:
	kubectl scale  --namespace database --replicas=3 statefulset/couchdb

couchdb-public-lb:
	kubectl create --namespace database -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-configmap.base.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-deployment.base.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-ingress.${PROVIDER}.yaml
	kubectl create --namespace database -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-service.${PROVIDER}.yaml

couchdb-dashboard:
	open $$(minikube service couchdb-cluster --namespace database --url)/_utils

rabbitmq-all: rabbitmq

rabbitmq:
	kubectl create --namespace message-bus -f secret-templates/rabbitmq-secret.yaml
	kubectl create --namespace message-bus -f catalog/rabbitmq/kubernetes/rabbitmq-discovery-service.yaml
	kubectl create --namespace message-bus -f catalog/rabbitmq/kubernetes/rabbitmq-ingress.${PROVIDER}.yaml
	kubectl create --namespace message-bus -f catalog/rabbitmq/kubernetes/rabbitmq-service.${PROVIDER}.yaml
	kubectl create --namespace message-bus -f catalog/rabbitmq/kubernetes/rabbitmq-statefulset.yaml

rabbitmq-scale:
	kubectl scale  --namespace message-bus --replicas=3 statefulset/rabbitmq

rabbitmq-dashboard:
	open $$(minikube service rabbitmq-cluster --namespace message-bus --url | grep ':31672')

jenkins-all: jenkins

jenkins:
	kubectl create --namespace continuous-integration -f secret-templates/jenkins-secret.yaml
	kubectl create --namespace continuous-integration -f catalog/jenkins/kubernetes/jenkins-discovery-service.yaml
	kubectl create --namespace continuous-integration -f catalog/jenkins/kubernetes/jenkins-ingress.${PROVIDER}.yaml
	kubectl create --namespace continuous-integration -f catalog/jenkins/kubernetes/jenkins-service.${PROVIDER}.yaml
	kubectl create --namespace continuous-integration -f catalog/jenkins/kubernetes/jenkins-master-pvc.yaml
	kubectl create --namespace continuous-integration -f catalog/jenkins/kubernetes/jenkins-deployment.yaml

jenkins-dashboard:
	minikube service jenkins-cluster --namespace continuous-integration
	kubectl logs $$(kubectl get pods --namespace continuous-integration --output=jsonpath={.items..metadata.name}) --namespace continuous-integration

install-dnsmasq:
	which dnsmasq || brew install dnsmasq
	sed -e 's/#conf-dir=.etc.dnsmasq.d.,\*.conf/conf-dir=\/etc\/dnsmasq.d\/,*.conf/' /usr/local/opt/dnsmasq/dnsmasq.conf.example > /usr/local/etc/dnsmasq.conf
	sudo mkdir -p /etc/dnsmasq.d
	sudo chown -R ${USER} /etc/dnsmasq.d
	sed -e 's/192.168.99.100/'$(minikube ip | tr -cd '[0-9.]')'/' samples/dnsmasq/minikube.cluster.local.conf > /etc/dnsmasq.d/minikube.cluster.local.conf
	sudo brew services start dnsmasq

up:
	minikube status || minikube start
	sed -e 's/192.168.99.100/'$$(minikube ip | tr -cd '[0-9.]')'/' samples/dnsmasq/minikube.cluster.local.conf > /etc/dnsmasq.d/minikube.cluster.local.conf
	sudo brew services restart dnsmasq

