#

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


NOTE:

Create an elb for TCP 22 on the master instance
Add a security group for port 22 from anywhere and attach it to the master
then ssh to that ELB
ssh -i ~/.ssh/id_rsa -o ServerAliveInterval=30 admin@AWS-ELB.com

