all: build push

build:
	docker build -t hbouvier/terminal .

push:
	docker push hbouvier/terminal

run:
	kubectl run terminal --rm --image=hbouvier/terminal --restart=Never --tty -i --generator=run-pod/v1 --overrides='{"apiVersion":"v1","kind":"Pod","metadata":{"name":"terminal"},"spec":{"containers":[{"name":"terminal","image": "hbouvier/terminal","imagePullPolicy":"Always","stdin":true,"stdinOnce": true,"tty": true,"volumeMounts": [{"name": "dockersock","mountPath":"/var/run/docker.sock"}],"env":[{"name":"DOCKER_API_VERSION","value":"1.23"}] }],"volumes":[{"name":"dockersock","hostPath":{"path":"/var/run/docker.sock"}}]}}'

run-no-docker:
	kubectl run terminal --rm --image=hbouvier/terminal --restart=Never --tty -i --generator=run-pod/v1

start:
	kubectl apply -f terminal-job.yaml

attach:
	kubectl attach -ti $$(kubectl get pod |grep terminal- | awk '{print $$1}')
