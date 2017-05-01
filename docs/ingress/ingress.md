# ingress

```bash
$ kubectl edit configmap nginx-load-balancer-conf --namespace kube-system
```

Add `enable-vts-status: "true"` to in the `data:` section as bellow.

```
data:
  enable-vts-status: "true"
  map-hash-bucket-size: "128"
```


Then run

```
$ open http://$(minikube ip):18080/nginx_status
```

