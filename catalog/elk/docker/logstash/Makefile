all: clean build push

clean:
	@echo ""

build:
	docker build -t hbouvier/logstash-kubernetes:5.4.0 .

push:
	docker push hbouvier/logstash-kubernetes:5.4.0