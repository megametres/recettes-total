include .env

.PHONY: build up down stop prune ps shell logs

default: up

## help	:	Print commands help.
help : Makefile
	@sed -n 's/^##//p' $<

## up	:	Start up containers.
up:
	@echo "Starting up containers for for $(PROJECT_NAME)..."
	docker-compose up -d --remove-orphans

## build	:	Build ruby image.
build:
	@echo "Building ruby image for for $(PROJECT_NAME)..."
	docker-compose pull
	docker-compose build

## new 	:	Remove existing related containers, build and start
new: prune build up

## start	:	Start containers without updating.
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	@docker-compose start

## down	:	Stop containers.
down: stop

## stop	:	Stop containers.
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	@docker-compose stop

## prune	:	Remove containers and their volumes.
prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker-compose down -v

## ps	:	List running containers.
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## shell	:	Access `ruby` container via shell.
shell:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_rust' --format "{{ .ID }}") /bin/bash

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs ruby	: View `ruby` container logs.
##		logs nginx ruby	: View `nginx` and `ruby` containers logs.
logs:
	@docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

# https://stackoverflow.com/a/6273809/1826109
%:
	@:
