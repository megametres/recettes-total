include .env

.PHONY: build up down stop prune ps shell logs

version_in_cargo:=`sed '3q;d' api/Cargo.toml | awk '{print $$3}' | tr -d \"`
version_in_package:=`sed '3q;d' frontend/package.json | awk '{print $$2}' | tr -d \",`

default: up


## build	:	Build the docker images.
build:
	@echo "Building ruby image for for $(PROJECT_NAME)..."
	docker-compose pull
	docker-compose build

## d	:	Shortcut for docker that will map on the selected environment
d:
	@docker $(filter-out $@,$(MAKECMDGOALS))

## dc	:	Shortcut for docker-compose that will map on the selected environment
dc:
	@docker-compose $(filter-out $@,$(MAKECMDGOALS))

## help	:	Print commands help.
help : Makefile
	@sed -n 's/^##//p' $<

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs ruby	: View `ruby` container logs.
##		logs nginx ruby	: View `nginx` and `ruby` containers logs.
logs:
	@docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

## local	:	Unset the DOCKER_ vars in the .env file
local:
ifeq ($(DEPLOYMENT_ENVIRONMENT), Local)
	@echo "Local environment already set"
else
	@echo "Set local environment"
	@echo "Commenting the DOCKER_ variables in the .env file"
	@sed -i 's/^DOCKER_/#DOCKER_/g' .env
	@sed -i 's/^DEPLOYMENT_ENVIRONMENT=Production/DEPLOYMENT_ENVIRONMENT=Local/g' .env
endif

## prod	:	Set the DOCKER_ vars in the .env file
prod:
ifeq ($(DEPLOYMENT_ENVIRONMENT), Production)
	@echo "Production environment already set"
else
	@echo "Set production environment"
	@echo "Uncommenting the DOCKER_ variables in the .env file"
	@sed -i 's/^#DOCKER_/DOCKER_/g' .env
	@sed -i 's/^DEPLOYMENT_ENVIRONMENT=Local/DEPLOYMENT_ENVIRONMENT=Production/g' .env
endif

## prune	:	Remove containers and their volumes.
prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	docker-compose down -v

## ps	:	List running containers.
ps:
	docker ps --filter name='$(PROJECT_NAME)*'

## shell	:	Access `ruby` container via shell.
shell:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_rust' --format "{{ .ID }}") /bin/bash

## stop	:	Stop containers.
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	docker-compose stop

## up	:	Start up containers.
up:
ifeq ($(DEPLOYMENT_ENVIRONMENT), Production)
	@echo -n "\e[31mAre you sure that you want to deploy on the production environment? (Y/N)\e[0m "
	@read confirmation; \
	if [ $$confirmation = "y" ] || [ $$confirmation = "Y" ]; \
	then \
		echo "Starting up containers for $(PROJECT_NAME) in the $(DEPLOYMENT_ENVIRONMENT) environment\n"\
		`docker-compose -f docker-compose-production.yml up -d`; \
	else \
		echo "Operation aborted."; \
	fi
else
	@echo "Starting up containers for $(PROJECT_NAME) in the $(DEPLOYMENT_ENVIRONMENT) environment"
	docker-compose up -d --remove-orphans
endif

version:
	@if [ $(API_VERSION) = $(version_in_cargo) ]; \
	then \
		echo "API_VERSION="$(version_in_cargo);\
	else \
		version_in_cargo=`sed '3q;d' api/Cargo.toml | awk '{print $$3}' | tr -d \"` && sed -i "s/API_VERSION=.*/API_VERSION=$$(echo $$version_in_cargo)/g" .env && \
		echo "Update the API_VERSION in the .env file according to the Cargo.toml  ($$version_in_cargo)";\
	fi
	@if [ $(FRONTEND_VERSION) = $(version_in_package) ]; \
	then \
		echo "FRONTEND_VERSION="$(version_in_package);\
	else \
		version_in_package=`sed '3q;d' frontend/package.json | awk '{print $$2}' | tr -d \",` && sed -i "s/FRONTEND_VERSION=.*/FRONTEND_VERSION=$$(echo $$version_in_package)/g" .env && \
		echo "Update the FRONTEND_VERSION in the .env file according to the package.json ($$version_in_package)";\
	fi


# https://stackoverflow.com/a/6273809/1826109
%:
	@:
