# export PATH := `pwd`/python-env/bin:$(PATH)
# export PYTHONPATH=./library/modules:python-env/lib/python2.7/
export PYTHONPATH=./library/modules

all: help

dependencies: pip
	pip install -r requirements.txt

fix-setuptools:
	pip install --upgrade setuptools --user python

fix-pip:
	pip install --upgrade pip

pip:
	which pip >/dev/null || (easy_install pip && pip install --upgrade pip)

minikube:
	ansible-playbook -i environments/local minikube.yml

gke:
	ansible-playbook -i environments/local gke.yml --extra-vars "configuration=${USER} rbac_namespace=acme project_name=${USER}s-sandbox cluster_name=sand-castle zone=us-west1-a"


help:
	@echo "\t$$ make dependencies"
	@echo "\t$$ make minikube"
	@echo "\t$$ make gke"
	@echo ""
	@echo 'If you get weird errors about `setuptools` try running:'
	@echo "\t$$ make fix-setuptools"
	@echo 'If you get a message that `pip` should be upgraded, run:'
	@echo "\t$$ make fix-pip"
