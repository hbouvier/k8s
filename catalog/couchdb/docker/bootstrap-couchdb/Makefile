# VERSION:=latest
VERSION:=2.0.0-001

all: clean build push

clean:
	rm -fr docker/bootstrap/coverage bootstrap/node_modules

build:
	docker build -t hbouvier/couchdb-bootstrap-kubernetes:${VERSION} .
	docker tag hbouvier/couchdb-bootstrap-kubernetes:${VERSION} hbouvier/couchdb-bootstrap-kubernetes:latest

push:
	docker push hbouvier/couchdb-bootstrap-kubernetes:${VERSION}
	docker push hbouvier/couchdb-bootstrap-kubernetes:latest