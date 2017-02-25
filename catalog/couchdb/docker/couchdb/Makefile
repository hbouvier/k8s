all: clean build push

clean:
	@echo ""

build:
	docker build -t hbouvier/couchdb:2.0.0 .

push:
	docker push hbouvier/couchdb:2.0.0