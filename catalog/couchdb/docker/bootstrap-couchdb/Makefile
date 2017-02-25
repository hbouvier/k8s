all: clean build push

clean:
	rm -fr docker/bootstrap/coverage bootstrap/node_modules

build:
	docker build -t hbouvier/couchdb-bootstrap-kubernetes:2.0.0 .

push:
	docker push hbouvier/couchdb-bootstrap-kubernetes:2.0.0