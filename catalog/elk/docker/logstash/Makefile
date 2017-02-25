all: clean build push

clean:
	@echo ""

build:
	docker build -t hbouvier/logstash-kubernetes:2.3 .

push:
	docker push hbouvier/logstash-kubernetes:2.3