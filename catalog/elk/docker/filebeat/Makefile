all: clean build push

clean:
	@echo ""

build:
	docker build -t hbouvier/filebeat-kubernetes:1.2.3 .

push:
	docker push hbouvier/filebeat-kubernetes:1.2.3