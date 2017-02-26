all: clean build push

clean:
	@echo ""

build:
	docker build -t hbouvier/rabbitmq-kubernetes:3.6.6-management .

push:
	docker push hbouvier/rabbitmq-kubernetes:3.6.6-management