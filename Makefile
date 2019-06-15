all: build run log
build:
	docker build -t test:latest .
run:
	docker run -itd --name rest-example -p 8888:80 test:latest
log:
	docker logs -f rest-example
exec:
	docker exec -it rest-example bash
clean:
	# docker kill rest-example && docker rm -f rest-example && docker image rm test:latest
	docker kill rest-example && docker rm -f rest-example 
test:
	curl localhost:8888/todos
	curl localhost:8888/todos/todo1
	curl http://localhost:8888/todos/todo2 -X DELETE
	curl http://localhost:8888/todos -d "task=something new" -X POST
	curl http://localhost:8888/todos/todo3 -d "task=something different" -X PUT
	curl localhost:8888/todos
