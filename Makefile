include .env

.PHONY: build help logs local prod prune ps push push rmi shell stop tag up

version_in_cargo:=`sed '3q;d' api/Cargo.toml | awk '{print $$3}' | tr -d \"`
version_in_package:=`sed '3q;d' frontend/package.json | awk '{print $$2}' | tr -d \",`

ifeq ($(DOCKER_TLS_VERIFY), 1)
	docker_command:=@docker --tlsverify --tlscacert=$(DOCKER_CERT_PATH)ca.pem --tlscert=$(DOCKER_CERT_PATH)cert.pem --tlskey=$(DOCKER_CERT_PATH)key.pem -H=$(DOCKER_HOST)
	docker_compose_command:=docker-compose --tlsverify --tlscacert=$(DOCKER_CERT_PATH)ca.pem --tlscert=$(DOCKER_CERT_PATH)cert.pem --tlskey=$(DOCKER_CERT_PATH)key.pem -H=$(DOCKER_HOST)
else
	docker_command:=@docker
	docker_compose_command:=docker-compose
endif

default: up


## build	:	Build the docker images.
build:
	@echo "Building ruby image for for $(PROJECT_NAME)..."
	$(docker_compose_command) pull
	$(docker_compose_command) build

## help	:	Print commands help.
help : Makefile
	@sed -n 's/^##//p' $<

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs ruby	: View `ruby` container logs.
##		logs nginx ruby	: View `nginx` and `ruby` containers logs.
logs:
	$(docker_compose_command) logs -f $(filter-out $@,$(MAKECMDGOALS))

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
	$(docker_compose_command) down -v
	$(docker_command) image prune

## ps	:	List running containers.
ps:
	$(docker_compose_command) ps

## push	:	Push the image to the registry
pull:
	$(docker_command) pull $(filter-out $@,$(MAKECMDGOALS))

## push	:	Push the image to the registry
push:
	$(docker_command) push $(filter-out $@,$(MAKECMDGOALS))

## rmi	:	Delete image
rmi:
	$(docker_command) rmi $(filter-out $@,$(MAKECMDGOALS))

## shell	:	Access `ruby` container via shell.
shell:
	$(docker_command) exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_rust' --format "{{ .ID }}") /bin/bash

## stop	:	Stop containers.
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	$(docker_compose_command) stop

## tag	:	Push the image to the registry
tag:
	$(docker_command) tag $(filter-out $@,$(MAKECMDGOALS))


## up	:	Start up containers.
up:
	echo
ifeq ($(DEPLOYMENT_ENVIRONMENT), Production)
	@echo -n "\e[31mAre you sure that you want to deploy on the production environment? (Y/N)\e[0m "
	@read confirmation; \
	if [ $$confirmation = "y" ] || [ $$confirmation = "Y" ]; \
	then \
		echo "Starting up containers for $(PROJECT_NAME) in the $(DEPLOYMENT_ENVIRONMENT) environment\n"\
		`$(docker_compose_command) -f docker-compose-production.yml up -d`; \
	else \
		echo "Operation aborted."; \
	fi
else
	@echo "Starting up containers for $(PROJECT_NAME) in the $(DEPLOYMENT_ENVIRONMENT) environment"
	$(docker_compose_command) up -d --remove-orphans
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
