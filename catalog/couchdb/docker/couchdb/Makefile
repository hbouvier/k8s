BASE_REPO:=klaemo/couchdb
BASE_VERSION:=2.0.0
VERSION:=2.0.0
NOW:=`date +%Y%m%d`

all: build

clean:
	@echo ""

build:
	docker pull ${BASE_REPO}:${BASE_VERSION}
	docker tag ${BASE_REPO}:${BASE_VERSION} hbouvier/couchdb:${VERSION}-${NOW}
	echo ${VERSION}-${NOW} > couchdb-from-version.txt
	docker push hbouvier/couchdb:${VERSION}-${NOW}