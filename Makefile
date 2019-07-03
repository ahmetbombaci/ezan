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

ha-install:
	docker run --init -d --name="home-assistant" -v /home/ahmet/Documents/github/ezan/home-assistant:/config -v /etc/localtime:/etc/localtime:ro --net=host homeassistant/home-assistant

ha-start:
	docker start home-assistant

ha-login:
	docker exec -it home-assistant bash
