# Introduction

# System Requirements

## Install Make

##### Install expect on Linux (Debian based)
```
sudo apt-get install make -y
```

##### Install expect on Linux (Red Hat / CentOS)
```
sudo yum install make
```

##### Install Make on OSX
```sh
brew install make
```

## Install Docker

Install docker if you do not have docker installed already.

##### Install Docker on Linux
Go to https://www.docker.com and follow the installation instructions.

Alternatively, a helper script is provided.
```bash
workbench/bin/get-docker.sh
```

Do not forget to add your user to the docker group.
**You may need to log out and back in for this to take effect!**
```
sudo usermod -aG docker `whoami`
newgrp docker
```

##### Install Docker on OSX
```text
Download and install the latest docker version:

https://www.docker.com/products/docker-desktop
```

## Install Docker Compose

Install the latest version of docker-compose. Your version of docker-compose must at least support the compose schema version **3.7**.

```bash
DOCKER_COMPOSE_VERSION=1.27.4
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

*If you are working on OSX and you get weird python (http related, file not found) errors try to update or re-install docker. There are numerous similar issues to be found online.*
*This seems to be a docker-thing on OSX. The problem magically disappeared when I tried to upgrade Docker and cancelled due to insufficient user rights.*
**Weird! I do not use OSX and won't bother to figure it out...**

## Optional Dependencies

Optionally install expect & xclip. Note that at this time I have removed all scripts that depend on xclip or expect.
However, in the future I may add or update scripts and assume these packages are available.

#### Install expect

Install expect to automate interactive commandline applications.

##### Install expect on Linux (Debian based)
```
sudo apt-get install expect -y
```

##### Install expect on Linux (Red Hat / CentOS)
```
sudo yum install expect
```

##### Install expect on OSX
```
brew install expect
```

#### Install xclip
Install xclip to copy data to the clipboard. 

##### Install xclip on Linux (Debian based)
```
sudo apt-get install xclip -y
```

##### Install expect on Linux (Red Hat / CentOS)
```
sudo yum install xclip
```

##### Install expect on OSX
```
brew install xclip
```

# Application Setup

### Checkout Application

Checkout the node application in `./app`.
```bash
git clone $REPOSITORY_URL workspace/app
```

The folder structure should look like this:

```text
/workspace
  /app
    /dist/...
    /src/...
    /package.json
```

### Required scripts in package.json

The docker setup depends on a couple of yarn scripts to run and build the application.
The functionality itself does not matter.

The following scripts MUST be available:

- **build**: The script `yarn build` generates a production build in the **./dist** directory
- **serve**: The script `yarn serve` serves the production build
- **watch**: The script`yarn watch` serves the development build
- **lint**:  The script`yarn lint` displays code style issues.
- **lint:fix**:  The script`yarn lint:fix` automatically fixes code style issues.

#### Example package.json
```json
{
  "scripts": {
    "build": "yarn tsc",
    "watch": "nodemon --watch \"src/**/*.ts\" --ignore \"node_modules/**/*\" --exec ts-node src/index.ts",
    "serve": "cross-env NODE_ENV=production REDIS_PORT=6379 node dist/index.js",
    "lint": "tslint --project tsconfig.json",
    "lint:fix": "tslint --project tsconfig.json --fix",
    "test": "yarn clean && yarn lint && yarn test:coverage",
    "test:unit": "cross-env NODE_ENV=test mocha  -r ts-node/register test/**/*Test.ts",
    "test:coverage": "cross-env NODE_ENV=test nyc mocha",
    "tsc": "tsc --project tsconfig.json",
    "tsc:w": "tsc --project tsconfig.json -w"
  }
}
```

# Get started

**Important:** At this point in time your application should have been cloned into in `workspace/app`. Verify before you continue.

## Initial setup

Copy .env.dist to .env to get started (Required).
Review the contents of the .env file and make changes if needed.
````bash
cp .env.dist .env
````

Let's start by verifying the current setup. You should see the output of the help target.
Or fix the problem if you see any errors.
````bash
make
````

### Volume Mount (OSX Only)

This docker setup detects the current OS version and sets up a NFS mount for docker.
The local mount is known to be very slow on OSX. At this time NFS is the fastest solution.

**The script is located in `/workbench/bin/setup-nfs-osx.sh`. Review the script if needed and use the make target to create the NFS mount.**

```bash
make nfs-osx
```


## Setup environment

##### Run installation script
```bash
make install
```


##### Open application in browser 

You should be get a response from the application. Open a browser and visit `http://app.local`.
Or if you changed the virtual host (APP_VIRTUAL_HOST) use that virtual host instead.

## **Docker Compose** - *Advanced Configuration*


### Environment Variables

The environment variables used for the docker-compose setup are mostly configurable in the .env file.
Docker compose will automatically look for this file and make the values available in the compose configs.
Some values are generated dynamically and added using the make file.

#### Dynamic Port Mapping

One example of a generated environment variable is a dynamically generated port mapping.
In we have **REDIS_HOST_PORT=1234** and **REDIS_PORT=4321** in .env than the port mapping would be: 1234:4321. 
This will expose a local port on the host system. If the host port is not defined (REDIS_HOST_PORT=) than the port mapping will 
be simply "4321".

In addition, there are a number of other dynamic values such as git hashes, uid, gid etc.

### User Permissions

A common issue when working with docker is that when files are created inside the container are owned by the user inside the container.
When the user has another UID you will run into permission issues. The ID's of the local user are used within the containers whenever possible to avoid such issues.

Build variables:
- DOCKER_UID
- DOCKER_GID


### Override Configuration

#### Builtin feature: docker-compose.override.yaml

Docker compose natively provides a feature to override docker-compose.yaml.
Simply copy docker-compose.override.yaml.dist to `docker-compose.override.yaml`.
This file overrides docker-compose.yaml.

#### Compose configuration

All files in ./compose can be overridden locally by adding the file to ./compose/override/. For example, to override `compose/dev.yaml`, simply copy the file to `compose/override/dev.yaml`. 
This file will be loaded INSTEAD of the original file. You can override configurations from sub directories as well.

For example:   
compose/lib/solr/dev.yaml -> compose/override/lib/solr/dev.yaml.

#### Override base service

This setup is reusing base services from `docker-compose.commons.yaml`. 
You can override the default commons file by adding the **DOCKER_COMPOSE_COMMONS** variable to the `.env` file.
For example: 
```dotenv
DOCKER_COMPOSE_COMMONS=docker-compose.other-commons.yaml
```

#### Override service configuration

#### Custom Dockerfile

You can set the DOCKERFILE variable to use a custom dockerfile. For example: DOCKERFILE=Dockerfile.local
You **must** make sure that all targets from the standard Dockerfile are available in the new file as well.

## Local Instance

Sometimes you just want to run the application locally. 
Assuming the application is using environment variables this should be pretty easy.
If the application depends on a service like Redis make sure to set the host port in .env. (REDIS_HOST_PORT).

For example:
````bash
PORT=8080 REDIS_HOST=localhost REDIS_PORT=16379 node dist/index.js
````

# Additional Services

## Portainer

A user interface to manage a docker environment.

*Environment variables with default values*
- **PORTAINER_ENABLED=true**
- **PORTAINER_VIRTUAL_HOST=portainer.local**
- **PORTAINER_HOST_PORT=**
- **PORTAINER_PORT=9000**

## Redis

*Environment variables with default values*
- **REDIS_ENABLED=true**
- **REDIS_IMAGE=redis:6.0-alpine**
- **REDIS_PORT=6379**
- **REDIS_HOST_PORT=**

## Solr

Support for the Solr search engine.

*Environment variables with default values*
- **SOLR_ENABLED=true**
- **SOLR_IMAGE=solr:latest**
- **SOLR_PORT=8983**
- **SOLR_HOST_PORT=**
- **SOLR_VIRTUAL_HOST=solr.local**


## RabbitMQ

Support for the RabbitMQ message queue.

*Environment variables with default values*
- **RABBITMQ_ENABLED=true**
- **RABBITMQ_IMAGE=rabbitmq:3.8.9-management-alpine**
- **RABBITMQ_PORT=5672**
- **RABBITMQ_HOST_PORT=**
- **RABBITMQ_UI_PORT=15672**
- **RABBITMQ_UI_HOST_PORT=**
- **RABBITMQ_UI_VIRTUAL_HOST=rabbitmq.local**
- **AMQP_URL=amqp://rabbitmq?connection_attempts=5&retry_delay=5**

## Mailhog

Support for mailhog, a in-memory SMTP server plus UI for development.

*Environment variables with default values*
- **MAILHOG_ENABLED=true**
- **MAILHOG_PORT=8025**
- **MAILHOG_HOST_PORT=**
- **MAILHOG_SMTP_PORT=1025**
- **MAILHOG_SMTP_HOST_PORT=**
- **MAILHOG_VIRTUAL_HOST=mailhog.local**
