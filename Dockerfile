# ---------------------------------------------- Build Time Arguments --------------------------------------------------
ARG DOCKER_UID
ARG DOCKER_GID

FROM node:16-alpine3.11 as app-base
ARG DOCKER_UID
ARG DOCKER_GID
ARG PORT
ENV DOCKER_UID $DOCKER_UID
ENV DOCKER_GID $DOCKER_GID
ENV PORT $PORT

RUN apk update && apk add build-base git python
RUN apk add --no-cache	shadow
ONBUILD RUN /usr/sbin/groupmod -g ${DOCKER_GID} node 2> /dev/null
#ONBUILD RUN /usr/sbin/useradd -l -s /bin/sh -g ${DOCKER_GID} -u ${DOCKER_UID} node
ONBUILD RUN /usr/sbin/usermod -g ${DOCKER_GID} -u ${DOCKER_UID} node 2> /dev/null
WORKDIR /var/www/app
COPY workspace/app/package.json .
COPY workspace/app/src ./src
EXPOSE ${PORT}

# Set perms and with setgid bit to recursively ensure correct owner
RUN chown ${DOCKER_UID}:${DOCKER_GID} /var/www/app -R
RUN chmod 2755 /var/www/app/
RUN find /var/www/app -type d -exec chmod 2755 {} \;

FROM app-base as app-prod
ENV NODE_ENV production
COPY workspace/app/yarn.lock .
COPY workspace/app/dist ./dist
RUN yarn install --production
ENV NODE_ENV production
CMD ["yarn", "serve"]

FROM app-base as app-dev
ENV NODE_ENV development
RUN yarn install
COPY workspace/app/test ./test
WORKDIR /var/www/app
CMD ["yarn", "watch"]


# -------------------------------------------------- ENTRYPOINT --------------------------------------------------------

# Add scripts and Entrypoint + clean!
COPY workbench/docker/healthcheck.sh			/usr/local/bin/docker-healthcheck
COPY workbench/docker/post-deployment.sh		/usr/local/bin/docker-post-deployment
COPY workbench/docker/bin/base/*		/usr/local/bin/
RUN  chmod +x /usr/local/bin/docker*

#HEALTHCHECK CMD ["docker-healthcheck"]
#CMD ["docker-base-entrypoint"]


