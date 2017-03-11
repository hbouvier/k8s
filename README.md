# Kubernetes Bootstrap

## Using MiniKube on your laptop

### Install KubeCtl and MiniKube

```bash
brew install kubectl
brew cask install minikube
```

### Create your local Kubernetes VM

```bash
minikube start --cpus 4 --disk-size 40g --memory 4096
kubectl create -f storage-class/minikube-storage-class.yaml
kubectl create -f catalog/heapster/kubernetes
minikube dashboard
```


## Deploying components from the Catalog

### ELK 

```bash
kubectl create namespace diagnostic
kubectl create -f catalog/elk/kubernetes --namespace diagnostic

minikube service elasticsearch --namespace diagnostic
open "$(minikube service elasticsearch --namespace diagnostic --url)/_cat/nodes?v"

kubectl create -f catalog/elk/kubernetes/logstash --namespace diagnostic
```

#### Kibana dashboard for logstash

```bash
kubectl create -f secret-templates/kibana-oauth-google-secret.yaml --namespace diagnostic
kubectl create -f catalog/elk/kubernetes/kibana --namespace diagnostic
minikube service kibana --namespace diagnostic
```


#### Manage ElasticSearch with Cerebro
```bash
kubectl create -f catalog/elk/kubernetes/cerebro --namespace diagnostic
minikube service cerebro --namespace diagnostic
```

#### Manage ElasticSearch with kopf (deprecated)

```bash
kubectl create -f catalog/elk/kubernetes/kopf --namespace diagnostic
kubectl port-forward $(kubectl get pod --namespace diagnostic | grep kopf | awk '{print $1}') 8080 --namespace diagnostic >& >/dev/null &
open http://localhost:8080/kopf
```


```bash
kubectl create namespace database
kubectl create -f secret-templates/couchdb-secrets.yaml --namespace database
kubectl create  --namespace database -f catalog/couchdb/kubernetes/
open $(minikube service couchdb --namespace database --url)/_utils
minikube service couchdb --namespace database
```


kubectl create -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-configmap.base.yaml --namespace database
kubectl create -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-deployement.base.yaml --namespace database
kubectl create -f catalog/couchdb/kubernetes/public-lb/couchdb-public-lb-service.minikube.yaml --namespace database



curl -XPUT -vu admin:secret http://192.168.99.100:30984/_users/org.couchdb.user:pouch -H 'Content-Type: application/json' -d '{"_id": "org.couchdb.user:pouch","name": "pouch","roles":["read-test-pouchdb-sync","write-test-pouchdb-sync"], "type":"user","password":"changeme"}'

curl -XPUT -vu admin:secret 192.168.99.100:30985/test-pouchdb-sync
curl -XPUT -vu admin:secret 192.168.99.100:30985/test-pouchdb-sync/_security   -H 'Content-Type: application/json' -d '{"admins":{"names":[],"roles":[]}, "members":{"names":["pouch"],"roles":[]}}'

curl -XPUT -vu admin:secret http://192.168.99.100:30984/_users/org.couchdb.user:anonymous -H 'Content-Type: application/json' -d '{"_id": "org.couchdb.user:anonymous","name": "anonymous","roles":[], "type":"user","password":"anonymous"}'



kubectl create namespace message-bus
kubectl create -f secret-templates/rabbitmq-secret.yaml --namespace message-bus
kubectl create -f catalog/rabbitmq/kubernetes --namespace message-bus
kubectl scale --replicas=2 statefulset/rabbitmq --namespace message-bus










## Use kops v1.4.4  (866ef8c)

(Follow) [https://github.com/kubernetes/kops/blob/master/docs/aws.md]

## Create the k8s cluster

```bash
kops create cluster \
    --dns-zone subdomain.domain.com \
    --zones us-east-1a \
    --master-zones us-east-1a \
    --node-count 2 \
    --node-size m3.medium \
    --master-size m4.large \
    --ssh-public-key ${HOME}/.ssh/id_rsa.pub \
    subdomain.domain.com
kops update cluster --name subdomain.domain.com --yes
```

## Enable log collections in ElasticSearch
```bash
copy secret-templates/* secrets/
kubectl create -f aws/ -f secrets/ -f elk/
open https://$(kubectl get  svc kibana --namespace kube-system --template='{{range .status.loadBalancer.ingress}}{{.hostname}}{{end}}')
```

## Enable k8s Dashboard

```bash
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.4.2/src/deploy/kubernetes-dashboard.yaml
kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/monitoring-standalone/v1.2.0.yaml
kops get secrets kube --type secret -oplaintext
open https://api.subdomain.domain.com/ui
```bash


## CREATE A NEW ADMIN USER

```bash
UUID=$(uuidgen)
echo -n '{"Data":"'${UUID}'"}' > /tmp/__USER_NAME__
s3cmd put /tmp/__USER_NAME__ s3://__K8S_BUCKET__/subdomain.domain.com/secrets/__USER_NAME__

kubectl config set-credentials __USER_NAME__/subdomain.domain.com --token=${UUID}
kubectl config set-cluster subdomain.domain.com --insecure-skip-tls-verify=true --server=https://api.subdomain.domain.com
kubectl config set-context default/subdomain.domain.com/__USER_NAME__ --user=__USER_NAME__/subdomain.domain.com --namespace=default --cluster=subdomain.domain.com
kubectl config use-context default/subdomain.domain.com/__USER_NAME__

curl -vk -H 'Authorization: Bearer '${UUID} https://api.subdomain.domain.com/api

kubectl get pod --all-namespaces
```

```bash
kubectl config view
    apiVersion: v1
    clusters:
    - cluster:
        insecure-skip-tls-verify: true
        server: https://subdomain.domain.com
      name: subdomain.domain.com
    contexts:
    - context:
        cluster: subdomain.domain.com
        namespace: default
        user: __USER_NAME__/subdomain.domain.com
      name: default/subdomain.domain.com/__USER_NAME__
    current-context: default/subdomain.domain.com/__USER_NAME__
    kind: Config
    preferences: {}
    users:
    - name: __USER_NAME__/subdomain.domain.com
      user:
        token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```



NOTE:

Create an elb for TCP 22 on the master instance
Add a security group for port 22 from anywhere and attach it to the master
then ssh to that ELB
ssh -i ~/.ssh/id_rsa -o ServerAliveInterval=30 admin@AWS-ELB.com

