help: run

build:
	docker build -t gcloud:latest docker/

run:
	docker run -ti --rm -w /tmp/ws -v $$(pwd):/tmp/ws gcloud:latest