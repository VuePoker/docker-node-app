ifneq (,)
  $(error This Makefile requires GNU Make. )
endif

# Make configuration
include Make.config
include Phony.config

ifeq ("$(wildcard .env)","")
$(error "The '.env' file is missing. Did you copy .env.dist to .env?")
endif

# Load default environment variables
-include .env

ENV ?= dev
ifeq ($(filter $(ENV),dev prod),)
$(error The ENV variable is invalid. must be one of <prod|dev> )
endif

DOCKERFILE ?= Dockerfile
ifeq ("$(wildcard $(DOCKERFILE))","")
$(error The file dockerfile ./${DOCKERFILE} does not exist! Check your settings or create the dockerfile.)
endif

ifeq ($(OS_NAME),linux)
	PROJECT_PREFIX ?= $(shell echo $(strip ${PROJECT}) | tr -s -c [:alnum:] -)
	NET_PREFIX := $(shell echo $(strip ${PROJECT}) | tr -s -c [:alnum:] _)
	NETWORK_ALIAS ?= $(NET_PREFIX)internal_net
else
	PROJECT_PREFIX ?= "app-"
	NETWORK_ALIAS ?= "app_internal_net"
endif

# Initialize values
PREFIX := $(PROJECT_PREFIX)
COMPOSE_FILES_PATH := -f docker-compose.yaml

# Initialize default values
VENDOR_NAME ?= undefined
HOSTS_CSV ?=
CMD_PREFIX ?=
DOCKER_COMPOSE_COMMONS ?= docker-compose.commons.yaml

#
# App Volume (defaults)
#

APP_VOLUME ?= $(PREFIX)app_volume
APP_VOLUME_DRIVER ?= "local"
APP_VOLUME_DRIVER_OPT_TYPE ?= "none"
APP_VOLUME_DRIVER_OPT_O ?= "bind"
APP_VOLUME_DRIVER_OPT_DEVICE ?= $(PWD)/workspace/app/

#
# OS specific (networks, volumes)
#

ifeq ($(OS_NAME),osx)
	OSX_NFS_ENABLED ?= false
	ifeq ($(OSX_NFS_ENABLED),true)
		APP_VOLUME_DRIVER_OPT_TYPE := "nfs"
		APP_VOLUME_DRIVER_OPT_O := "addr=host.docker.internal,rw,nolock,hard,nointr,nfsvers=3"
		ifeq ($(OSX_CATALINA_OR_GREATER),true)
			APP_VOLUME_DRIVER_OPT_DEVICE := :/System/Volumes/Data/$(PWD)/workspace/app
		else
			APP_VOLUME_DRIVER_OPT_DEVICE := $(PWD)/workspace/app/
		endif
	endif
endif

#
# OS specific compose file
#

ifneq ("$(wildcard compose/override/os/$(OS_NAME)/$(ENV).yaml)","")
	COMPOSE_FILES_PATH +=  -f ./compose/override/os/${OS_NAME}/${ENV}.yaml
else
	ifneq ("$(wildcard compose/os/$(OS_NAME)/$(ENV).yaml)","")
		COMPOSE_FILES_PATH +=  -f ./compose/os/${OS_NAME}/${ENV}.yaml
	endif
endif

CMD_PREFIX += APP_VOLUME_DRIVER=$(APP_VOLUME_DRIVER)
CMD_PREFIX += APP_VOLUME_DRIVER_OPT_TYPE=$(APP_VOLUME_DRIVER_OPT_TYPE)
CMD_PREFIX += APP_VOLUME_DRIVER_OPT_O=$(APP_VOLUME_DRIVER_OPT_O)
CMD_PREFIX += APP_VOLUME_DRIVER_OPT_DEVICE=$(APP_VOLUME_DRIVER_OPT_DEVICE)


#
# Mailhog (SMTP server for development)
#

ifeq ($(MAILHOG_ENABLED),true)
	HOSTS_CSV += ,$(MAILHOG_VIRTUAL_HOST)
	ifeq ($(ENV),dev)
		ifneq ("$(wildcard compose/override/lib/mailhog/$(ENV).yaml)","")
		   COMPOSE_FILES_PATH +=  -f ./compose/override/lib/mailhog/$(ENV).yaml
		else
		   COMPOSE_FILES_PATH +=  -f ./compose/lib/mailhog/$(ENV).yaml
		endif
	endif
	ifeq ($(MAILHOG_HOST_PORT),)
		CMD_PREFIX += MAILHOG_PORT_MAPPING=$(MAILHOG_PORT)
	else
		CMD_PREFIX += MAILHOG_PORT_MAPPING=$(MAILHOG_HOST_PORT):$(MAILHOG_PORT)
	endif
	ifeq ($(MAILHOG_SMTP_HOST_PORT),)
		CMD_PREFIX += MAILHOG_SMTP_PORT_MAPPING=$(MAILHOG_SMTP_PORT)
	else
		CMD_PREFIX += MAILHOG_SMTP_PORT_MAPPING=$(MAILHOG_SMTP_HOST_PORT):$(MAILHOG_SMTP_PORT)
	endif
endif

#
# Redis
#
ifeq ($(REDIS_ENABLED),true)
	ifneq ("$(wildcard compose/override/lib/redis/$(ENV).yaml)","")
		COMPOSE_FILES_PATH +=  -f ./compose/override/lib/redis/$(ENV).yaml
	else
		COMPOSE_FILES_PATH +=  -f ./compose/lib/redis/$(ENV).yaml
	endif
	ifeq ($(REDIS_HOST_PORT),)
		CMD_PREFIX += REDIS_PORT_MAPPING=$(REDIS_PORT)
	else
		CMD_PREFIX += REDIS_PORT_MAPPING=$(REDIS_HOST_PORT):$(REDIS_PORT)
	endif
endif


#
# MONGODB
#
ifeq ($(MONGODB_ENABLED),true)
	HOSTS_CSV += ,$(MONGOKU_VIRTUAL_HOST)
	ifneq ("$(wildcard compose/override/lib/mongodb/$(ENV).yaml)","")
		COMPOSE_FILES_PATH +=  -f ./compose/override/lib/mongodb/$(ENV).yaml
	else
		COMPOSE_FILES_PATH +=  -f ./compose/lib/mongodb/$(ENV).yaml
	endif
	ifeq ($(MONGODB_HOST_PORT),)
		CMD_PREFIX += MONGODB_PORT_MAPPING=$(MONGODB_PORT)
	else
		CMD_PREFIX += MONGODB_PORT_MAPPING=$(MONGODB_HOST_PORT):$(MONGODB_PORT)
	endif
endif

#
# RabbitMQ
#
ifeq ($(RABBITMQ_ENABLED),true)
	HOSTS_CSV += ,$(RABBITMQ_UI_VIRTUAL_HOST)
    ifneq ("$(wildcard compose/override/lib/rabbitmq/$(ENV).yaml)","")
       COMPOSE_FILES_PATH +=  -f ./compose/override/lib/rabbitmq/$(ENV).yaml
    else
       COMPOSE_FILES_PATH +=  -f ./compose/lib/rabbitmq/$(ENV).yaml
    endif
	ifeq ($(RABBITMQ_HOST_PORT),)
		CMD_PREFIX += RABBITMQ_PORT_MAPPING=$(RABBITMQ_PORT)
	else
		CMD_PREFIX += RABBITMQ_PORT_MAPPING=$(RABBITMQ_HOST_PORT):$(RABBITMQ_PORT)
	endif
	ifeq ($(RABBITMQ_UI_HOST_PORT),)
		CMD_PREFIX += RABBITMQ_UI_PORT_MAPPING=$(RABBITMQ_UI_PORT)
	else
		CMD_PREFIX += RABBITMQ_UI_PORT_MAPPING=$(RABBITMQ_UI_HOST_PORT):$(RABBITMQ_UI_PORT)
	endif
endif

#
# Portainer (Docker Management UI)
#
ifeq ($(PORTAINER_ENABLED),true)
	HOSTS_CSV += ,$(PORTAINER_VIRTUAL_HOST)
    ifneq ("$(wildcard compose/override/lib/portainer/$(ENV).yaml)","")
       COMPOSE_FILES_PATH +=  -f ./compose/override/lib/portainer/$(ENV).yaml
    else
       COMPOSE_FILES_PATH +=  -f ./compose/lib/portainer/$(ENV).yaml
    endif
	ifeq ($(PORTAINER_HOST_PORT),)
		CMD_PREFIX += PORTAINER_PORT_MAPPING=$(PORTAINER_PORT)
	else
		CMD_PREFIX += PORTAINER_PORT_MAPPING=$(PORTAINER_HOST_PORT):$(PORTAINER_PORT)
	endif
endif

#
# Solr
#
ifeq ($(SOLR_ENABLED),true)
	HOSTS_CSV += ,$(SOLR_VIRTUAL_HOST)
    ifneq ("$(wildcard compose/override/lib/solr/$(ENV).yaml)","")
       COMPOSE_FILES_PATH +=  -f ./compose/override/lib/solr/$(ENV).yaml
    else
       COMPOSE_FILES_PATH +=  -f ./compose/lib/solr/$(ENV).yaml
    endif
	ifeq ($(SOLR_HOST_PORT),)
		CMD_PREFIX += SOLR_PORT_MAPPING=$(SOLR_PORT)
	else
		CMD_PREFIX += SOLR_PORT_MAPPING=$(SOLR_HOST_PORT):$(SOLR_PORT)
	endif
endif

ifneq ("$(wildcard compose/override/$(ENV).yaml)","")
    COMPOSE_FILES_PATH +=  -f ./compose/override/$(ENV).yaml
else
    COMPOSE_FILES_PATH +=  -f ./compose/$(ENV).yaml
endif


# The host string is a comma separated string containing the virtual hosts of the application.
# The virtual host optional services portainer may be added as well.
HOSTS_CSV += ,$(APP_VIRTUAL_HOST)
HOSTS_STRING := $(shell echo $(HOSTS_CSV) | tr ',' ' ')
NUM_HOSTS = $(words $(HOSTS_STRING))

# Dynamic app port mapping
ifeq ($(APP_HOST_PORT),)
	CMD_PREFIX += APP_PORT_MAPPING=$(APP_PORT)
else
	CMD_PREFIX += APP_PORT_MAPPING=$(APP_HOST_PORT):$(APP_PORT)
endif

#$(error ${CMD_PREFIX})

# The CMD prefix provides a number of generic arguments that we want to make generally available.
CMD_PREFIX += DOCKERFILE=$(DOCKERFILE) DOCKER_UID=$(DOCKER_UID) DOCKER_GID=$(DOCKER_GID)
CMD_PREFIX += PROJECT=$(PROJECT) PREFIX=$(PREFIX) NETWORK_ALIAS=$(NETWORK_ALIAS)
CMD_PREFIX += APP_VERSION=$(APP_VERSION) APP_ENV=$(ENV) APP_VOLUME=$(APP_VOLUME)
CMD_PREFIX += BUILD_COMMIT=$(BUILD_COMMIT) APP_COMMIT=$(APP_COMMIT)
CMD_PREFIX += VENDOR_NAME=$(VENDOR_NAME)
CMD_PREFIX += DOCKER_COMPOSE_COMMONS=$(DOCKER_COMPOSE_COMMONS)

# --------------------------

.PHONY: $(MAKE_PHONY_TARGETS)

install: ## Run install command
	@make pre-install
	@make build
	@make up
	@make post-install

clean-install: ## Cleanup and run fresh install.
	@-make down
	@-make install

uninstall: ## Remove containers, volumes, networks and virtual hosts.
	@make clean
	@make remove-hosts

build:	  ## Run build command
	@make pre-build
	@${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) build
	@make post-build

build-no-cache:	## Build The Image without cache (will take significantly longer but may avoid/solve dependency related problems)
	@make pre-build
	${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) build --no-cache
	@make post-build

up:	 ## Start containers (build if necessary)
	${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) --compatibility up --build -d
	@- make router

start:	 ## Resume containers
	${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) --compatibility up -d
	@- make router

clean: ## Removes containers, volumes and networks
	@-make down
	@-make volume-rm
	@-make network-rm

down:	  ## Stop and remove containers
	${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) down

stop:	  ## Stop containers
	@- $(DOCKER_BIN) stop `$(DOCKER_BIN) ps --filter name=$(PREFIX) -q`

ps: ## Lists project containers
	$(DOCKER_BIN) container ls --all --filter=name=$(PREFIX)

logs:	  ## Tail container logs
	@${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) logs --follow --tail=1000

images:	  ## Show project images
	@${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) images

network-ls: ## List networks
	$(DOCKER_BIN) network ls --filter name=$(PROJECT)

volume-ls: ## Lists volumes
	$(DOCKER_BIN) volume ls --filter name=${PROJECT}

restart:   ## Restart containers
	@${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) restart

stats: ## Dump stats
	@$(DOCKER_BIN) stats --all --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

yarn: ## Install frontend packages
	$(DOCKER_BIN) run --rm -it \
		-v ${PWD}/workspace/app:/app \
		-e UID=${DOCKER_UID} \
		-e GID=${DOCKER_GID} \
		node bash -ci " \
			mkdir -p /root/.npm /app/node_modules && \
			cd /app && \
			yarn --$(ENV) install --force && \
			yarn run build \
			chown $(DOCKER_UID):$(DOCKER_GID) /app/dist/ -R \
			chown $(DOCKER_UID):$(DOCKER_GID) /app/node_modules/ -R \
		"

#
# Utility targets
#

nfs-osx: ## Create NFS mount on MacOS
	@if [ "${OS_NAME}" != "osx" ];  then \
	  	echo "Error: Target is for OSX only! "; \
	  	exit 64; \
	fi
	$(PWD)/workbench/bin/setup-nfs-osx.sh; \

dump:	 ## Dump final docker-compose configuration
	@${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) config

vars:	 ## Dump variables
	@echo "==========================================================="
	@echo "BUILD VARS"
	@echo "==========================================================="
	@echo "ENV: ${ENV}"
	@echo "OS_NAME: ${OS_NAME}"
	@echo "PREFIX: ${PREFIX}"
	@echo "PROJECT: ${PROJECT}"
	@echo "DOCKER_UID: ${DOCKER_UID}"
	@echo "DOCKER_GID: ${DOCKER_GID}"
	@echo "DOCKERFILE: ${DOCKERFILE}"
	@echo "NETWORK_ALIAS: ${NETWORK_ALIAS}"
	@echo "DOCKER_NETWORK_DRIVER: ${DOCKER_NETWORK_DRIVER}"
	@echo "DOCKER_DEFAULT_INTERNAL_SUBNET: ${DOCKER_DEFAULT_INTERNAL_SUBNET}"
	@echo "CMD_PREFIX: ${CMD_PREFIX}"
	@echo "DOCKER_BIN: ${DOCKER_BIN}"
	@echo "DOCKER_COMPOSE_BIN: ${DOCKER_COMPOSE_BIN}"
	@echo "COMPOSE_FILES_PATH: ${COMPOSE_FILES_PATH}"
	@echo "HOSTS_CSV: ${HOSTS_CSV}"
	@echo "HOSTS_STRING: ${HOSTS_STRING}"
	@echo "NUM_HOSTS: ${NUM_HOSTS}"
	@echo "BUILD_COMMIT: ${BUILD_COMMIT}"
	@echo "DOCKER_BUILD_VERSION: ${DOCKER_BUILD_VERSION}"
	@echo "DOCKER_BUILD_DATE: ${DOCKER_BUILD_DATE}"
	@echo "==========================================================="
	@echo "APPLICATION VOLUME"
	@echo "==========================================================="
	@echo "APP_VOLUME: ${APP_VOLUME}"
	@echo "APP_VOLUME_DRIVER: ${APP_VOLUME_DRIVER}"
	@echo "APP_VOLUME_DRIVER_OPT_TYPE: ${APP_VOLUME_DRIVER_OPT_TYPE}"
	@echo "APP_VOLUME_DRIVER_OPT_O: ${APP_VOLUME_DRIVER_OPT_O}"
	@echo "APP_VOLUME_DRIVER_OPT_DEVICE: ${APP_VOLUME_DRIVER_OPT_DEVICE}"
	@echo "OSX_NFS_ENABLED: ${OSX_NFS_ENABLED}"
	@echo "==========================================================="
	@echo "SOLR"
	@echo "==========================================================="
	@echo "APP_COMMIT: ${APP_COMMIT}"
	@echo "APP_VERSION: ${APP_VERSION}"
	@echo "APP_VIRTUAL_HOST: ${APP_VIRTUAL_HOST}"
	@echo "APP_HOST_PORT: ${APP_HOST_PORT}"
	@echo "APP_PORT: ${APP_PORT}"
	@echo "==========================================================="
	@echo "RABBITMQ"
	@echo "==========================================================="
	@echo "RABBITMQ_ENABLED: ${RABBITMQ_ENABLED}"
	@echo "RABBITMQ_IMAGE: ${RABBITMQ_IMAGE}"
	@echo "RABBITMQ_PORT: ${RABBITMQ_PORT}"
	@echo "RABBITMQ_HOST_PORT: ${RABBITMQ_HOST_PORT}"
	@echo "RABBITMQ_UI_HOST_PORT: ${RABBITMQ_UI_HOST_PORT}"
	@echo "RABBITMQ_UI_PORT: ${RABBITMQ_UI_PORT}"
	@echo "RABBITMQ_UI_VIRTUAL_HOST: ${RABBITMQ_UI_VIRTUAL_HOST}"
	@echo "AMQP_URL: ${AMQP_URL}"
	@echo "==========================================================="
	@echo "SOLR"
	@echo "==========================================================="
	@echo "SOLR_ENABLED: ${SOLR_ENABLED}"
	@echo "SOLR_IMAGE: ${SOLR_IMAGE}"
	@echo "SOLR_VIRTUAL_HOST: ${SOLR_VIRTUAL_HOST}"
	@echo "SOLR_HOST_PORT: ${SOLR_HOST_PORT}"
	@echo "SOLR_PORT: ${SOLR_PORT}"
	@echo "==========================================================="
	@echo "PORTAINER"
	@echo "==========================================================="
	@echo "PORTAINER_ENABLED: ${PORTAINER_ENABLED}"
	@echo "PORTAINER_VIRTUAL_HOST: ${PORTAINER_VIRTUAL_HOST}"
	@echo "PORTAINER_HOST_PORT: ${PORTAINER_HOST_PORT}"
	@echo "PORTAINER_PORT: ${PORTAINER_PORT}"
	@echo "==========================================================="
	@echo "REDIS"
	@echo "==========================================================="
	@echo "REDIS_ENABLED: ${REDIS_ENABLED}"
	@echo "REDIS_IMAGE: ${REDIS_IMAGE}"
	@echo "REDIS_HOST_PORT: ${REDIS_HOST_PORT}"
	@echo "REDIS_PORT: ${REDIS_PORT}"
	@echo "==========================================================="
	@echo "MAILHOG"
	@echo "==========================================================="
	@echo "MAILHOG_ENABLED: ${MAILHOG_ENABLED}"
	@echo "MAILHOG_VIRTUAL_HOST: ${MAILHOG_VIRTUAL_HOST}"
	@echo "MAILHOG_HOST_PORT: ${MAILHOG_HOST_PORT}"
	@echo "MAILHOG_PORT: ${MAILHOG_PORT}"
	@echo "MAILHOG_SMTP_HOST_PORT: ${MAILHOG_SMTP_HOST_PORT}"
	@echo "MAILHOG_SMTP_PORT: ${MAILHOG_SMTP_PORT}"
	@echo "==========================================================="
	@echo "MONGODB"
	@echo "==========================================================="
	@echo "MONGODB_ENABLED: ${MAILHOG_ENABLED}"
	@echo "MONGODB_IMAGE: ${MONGODB_IMAGE}"
	@echo "MONGODB_USERNAME: ${MONGODB_USERNAME}"
	@echo "MONGODB_PASSWORD: ${MONGODB_PASSWORD}"
	@echo "MONGODB_DATABASE: ${MONGODB_DATABASE}"
	@echo "MONGODB_HOST_PORT: ${MONGODB_HOST_PORT}"
	@echo "MONGODB_PORT: ${MONGODB_PORT}"
	@echo "MONGOKU_VIRTUAL_HOST: ${MONGOKU_VIRTUAL_HOST}"
	@echo "MONGOKU_PORT: ${MONGOKU_PORT}"
	@echo "MONGOKU_COUNT_TIMEOUT: ${MONGOKU_COUNT_TIMEOUT}"


add-hosts: ## Create virtual hosts
	@ echo "Creating virtual hosts..."
	@if [ ${NUM_HOSTS} -eq 0 ]; then \
	    echo "Failed to initialize virtual hosts. Hosts not found..."; \
      	exit 64; \
	fi
	@if [ ${NUM_HOSTS} -gt 1 ]; then \
	  for hostname in $(HOSTS_STRING) ; \
		do \
		  echo $$hostname; \
	      workbench/bin/virtual-host.sh add $$hostname; \
		done \
	else \
		echo $$HOSTS_STRING; \
		workbench/bin/virtual-host.sh add $$HOSTS_STRING; \
	fi

remove-hosts: ## Remove virtual hosts
	#${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) down -v --rmi all --remove-orphans
	@ echo "Removing virtual hosts..."
	@if [ ${NUM_HOSTS} -eq 0 ]; then \
	    echo "Failed to initialize virtual hosts. Hosts not found..."; \
      	exit 64; \
	fi
	@if [ ${NUM_HOSTS} -gt 1 ]; then \
	  for hostname in $(HOSTS_STRING) ; \
		do \
		  echo $$hostname; \
	      workbench/bin/virtual-host.sh remove $$hostname; \
		done \
	else \
		echo $(HOSTS_STRING); \
		workbench/bin/virtual-host.sh remove $$HOSTS_STRING; \
	fi

router: ## Automatically discover containerized virtual hosts and forward requests the docker container.
	@- $(DOCKER_BIN) stop ${PREFIX}-router > /dev/null
	@- $(DOCKER_BIN) rm ${PREFIX}-router > /dev/null
	$(DOCKER_BIN) run -d --network $(NETWORK_ALIAS) --name ${PREFIX}-router -p 80:80 -p 443:443 -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy

hosts: ## Print virtual hosts
	@echo "==============================\nDumping virtual hosts\n=============================="
	@echo "APPLICATION: ${APP_VIRTUAL_HOST}";
	@if [ "${SOLR_ENABLED}" = "true" ];  then \
		echo "SOLR: ${SOLR_VIRTUAL_HOST}"; \
	fi
	@if [ "${MAILHOG_ENABLED}" = "true" ];  then \
		echo "MAILHOG: ${MAILHOG_VIRTUAL_HOST}"; \
	fi
	@if [ "${MONGODB_ENABLED}" = "true" ];  then \
		echo "MONGOKU: ${MONGOKU_VIRTUAL_HOST}"; \
	fi
	@if [ "${PORTAINER_ENABLED}" = "true" ];  then \
		echo "PORTAINER: ${PORTAINER_VIRTUAL_HOST}"; \
	fi
	@if [ "${RABBITMQ_ENABLED}" = "true" ];  then \
		echo "RABBIT MQ: ${RABBITMQ_UI_VIRTUAL_HOST}"; \
	fi

ssh: ## Open shell application container
	@${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) exec app /bin/sh

redis-ssh: ## Open shell Redis container
	@if [ "${REDIS_ENABLED}" != "true" ];  then \
		echo "Redis is not containerized. To containerize Redis, set REDIS_ENABLED to 'true' and rebuild the environment."; \
		exit 64; \
	fi
	@${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) exec redis /bin/sh

redis-cli: ## Open shell to Redis CLI
	@if [ "${REDIS_ENABLED}" != "true" ];  then \
		echo "Redis is not containerized. To containerize Redis, set REDIS_ENABLED to 'true' and rebuild the environment."; \
		exit 64; \
	fi
	@${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) exec redis /bin/sh -c 'redis-cli'

lint: ## Run linters
	@- make lint-yaml
	@- make es-lint

lint-yaml: ## Run yaml linter
	@ echo "Run yamllint..."
	$(DOCKER_BIN) run --rm $$(tty -s && echo "-it" || echo) -v $(PWD)/workspace/app:/data cytopia/yamllint:latest .
	@ echo "Yaml lint complete...\n"

es-lint: ## Run es-lint linter
	@ echo "Run es-lint..."
	$(DOCKER_BIN) run --rm $$(tty -s && echo "-it" || echo) -v $(PWD)/workspace/app:/data cytopia/eslint:latest .
	@ echo "Yaml es-lint complete...\n"

help:  ## Show this help.
	@echo "Make Application Docker Images and Containers using Docker-Compose files in 'docker' Dir."
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m ENV=<prod|dev> (default: dev) \n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

#
# PRIVATE TARGETS
#
# These targets should not be used directy. Private targets may depend on a certain state or execution order.
#
# NOTE:
# The help command will display all commands with a duplicate hashtag comment.
# Use only 1 # after the target definition to avoid showing private targets.
#

network-init: # Create docker network for current project.
	- $(DOCKER_BIN) network create $(NETWORK_ALIAS) -d $(DOCKER_NETWORK_DRIVER) --attachable \
 		--label="app.vcs-ref=$(APP_COMMIT)" \
 		--label="app.version=$(APP_VERSION)" \
 		--label="app.env=$(ENV)" \
 		--label="app.project_label=$(PROJECT)" \
 		--label="app.build_prefix=$(PREFIX)" \
 		--label="org.label-schema.vendor=$(VENDOR_NAME)" \
 		--label="org.label-schema.build-date=$(DOCKER_BUILD_DATE)" \
 		--label="org.label-schema.schema-version=$(LABEL_SCHEMA_SPEC_VERSION)" \
 		--label="org.label-schema.version=$(DOCKER_BUILD_VERSION)" \
 		--label="org.label-schema.vcs-url=$(DOCKER_BUILD_REPOSITORY_URL)" \
 		--label="org.label-schema.vcs-ref=$(BUILD_COMMIT)"

network-rm: # Remove networks
	@ echo "Remove networks..."
	@- $(DOCKER_BIN) network rm $$($(DOCKER_BIN) network ls --filter name=$(PREFIX) -q)

volume-init: # Create project volumes
	@ echo "Create volumes..."
	- $(DOCKER_BIN) volume create ${APP_VOLUME}  --label app.project.build_prefix=${PREFIX} --label=app.project_label=${PROJECT} --label=app.version=${APP_VERSION}

volume-rm: # Remove volumes
	@ echo "Remove volumes..."
	- $(DOCKER_BIN) volume rm $$($(DOCKER_BIN) volume ls --filter name=${PREFIX} -q)

volume-rm-all: # Remove ALL volumes from all sites in THIS project (including shared volumes)
	@ echo "Remove ALL volumes in THIS project..."
	- $(DOCKER_BIN) volume rm $$($(DOCKER_BIN) volume ls --filter label=${PROJECT} -q)

volume-ls-all: # List ALL volumes from all sites in THIS project.
	@ echo "Listing volumes..."
	$(DOCKER_BIN) volume ls --filter label=${PROJECT}

pre-install: # This is a private target. Add functionality here that must run BEFORE EVERY installation.
	@-make add-hosts

post-install: # This is a private target. Add functionality here that must run AFTER EVERY installation.
	@make router

pre-build: # This is a private target. Add functionality here that must run BEFORE EVERY build.
	@- make network-rm 2> /dev/null
	@- make network-init

post-build: # This is a private target. Add functionality here that must run AFTER EVERY build.
	@ echo "Build finished..."

#solr-create-collections: ## Create solr configuration
#	@${CMD_PREFIX} $(DOCKER_COMPOSE_BIN) $(COMPOSE_FILES_PATH) exec solr /bin/sh -c '/opt/solr/bin/solr create -n data_driven_schema_configs -c foobar'