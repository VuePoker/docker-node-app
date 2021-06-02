# syntax=docker/dockerfile:1.0.0-experimental

# TO USE THE NEW EXPERIMENTAL SYNTAX YOU MUST PROVIDE THIS ENVIRONMENT VARIABLE:
# DOCKER_BUILDKIT=1

FROM node:alpine
RUN apk add --update git openssh

RUN mkdir -p /root/.npm /app/node_modules /app

VOLUME /app

WORKDIR /app

# This command will have access to the forwarded agent (if one is
# available)
RUN --mount=type=ssh yarn --dev