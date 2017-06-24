all: clean build push

clean:
	@echo ""

build:
	docker build -t hbouvier/elasticsearch-kubernetes:5.2.0-001 .

push:
	docker push hbouvier/elasticsearch-kubernetes:5.2.0-001