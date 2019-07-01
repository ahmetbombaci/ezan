test:
	echo "hello"

build:
	docker build -t my-alpine .

run:
	docker stop my-alpine-local
	docker rm my-alpine-local
	docker run -dit --name="my-alpine-local" --network host my-alpine

login:
	docker exec -it my-alpine-local bash

logs:
	docker logs my-alpine-local
