FROM alpine:latest as eslint-builder

RUN set -eux \
	&& apk add --no-cache \
		nodejs-current \
		npm

ARG VERSION=latest
RUN set -eux \
	&& if [ ${VERSION} = "latest" ]; then \
		npm install global --production --remove-dev eslint; \
	else \
		npm install global --production --remove-dev eslint@^${VERSION}.0.0; \
	fi \
	\
	&& /node_modules/eslint/bin/eslint.js --version | grep -E '^v?[0-9]+'

# Remove unecessary files
RUN set -eux \
	&& find /node_modules -type d -iname 'test' -prune -exec rm -rf '{}' \; \
	&& find /node_modules -type d -iname 'tests' -prune -exec rm -rf '{}' \; \
	&& find /node_modules -type d -iname 'testing' -prune -exec rm -rf '{}' \; \
	&& find /node_modules -type d -iname '.bin' -prune -exec rm -rf '{}' \; \
	\
	&& find /node_modules -type f -iname '.*' -exec rm {} \; \
	&& find /node_modules -type f -iname 'LICENSE*' -exec rm {} \; \
	&& find /node_modules -type f -iname 'Makefile*' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.bnf' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.css' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.def' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.flow' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.html' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.info' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.jst' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.lock' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.map' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.markdown' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.md' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.mjs' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.mli' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.png' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.ts' -exec rm {} \; \
	&& find /node_modules -type f -iname '*.yml' -exec rm {} \;


FROM alpine:latest as es-lint
COPY --from=eslint-builder /node_modules/ /node_modules/
RUN set -eux \
	&& apk add --no-cache nodejs-current \
	&& ln -sf /node_modules/eslint/bin/eslint.js /usr/bin/eslint

WORKDIR /data
ENTRYPOINT ["eslint"]
CMD ["--help"]