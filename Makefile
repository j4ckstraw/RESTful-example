all: build run log
build:
	docker build -t test:latest .
run:
	docker run -itd --name rest-example test:latest
log:
	docker logs -f rest-example
exec:
	docker exec -it rest-example bash
clean:
	docker kill rest-example && docker rm -f rest-example && docker image rm test:latest
