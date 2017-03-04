all: clean build push

clean:
	@echo ""

build:
	docker build -t hbouvier/kopf-kubernetes:latest .

push:
	docker push hbouvier/kopf-kubernetes:latest