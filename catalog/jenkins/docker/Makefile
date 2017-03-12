all: clean build push

clean:
	@echo ""

build:
	docker build -t hbouvier/jenkins-kubernetes:2.32.3 .

push:
	docker push hbouvier/jenkins-kubernetes:2.32.3