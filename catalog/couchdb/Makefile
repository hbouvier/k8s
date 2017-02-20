all: clean build push

clean:
	rm -fr bootstrap/coverage bootstrap/node_modules

build:
	docker build -t hbouvier/couchdb-k8s-bootstrap .

push:
	docker push hbouvier/couchdb-k8s-bootstrap