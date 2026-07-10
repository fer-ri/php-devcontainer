ARG PHP_VERSION=8.5
ARG NODE_IMAGE=node:24-alpine
FROM ${NODE_IMAGE} AS node_src
FROM serversideup/php:${PHP_VERSION}-fpm-nginx-alpine AS base
USER root
RUN install-php-extensions bcmath intl exif gd

FROM base AS dev
USER root
RUN apk add --no-cache shadow openssh git
COPY --from=node_src /usr/local/bin/node /usr/local/bin/node
COPY --from=node_src /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
 && usermod -s /bin/sh www-data
COPY docker/entrypoint.d/10-fix-uid.sh /etc/entrypoint.d/10-fix-uid.sh
RUN chmod 755 /etc/entrypoint.d/10-fix-uid.sh

FROM base AS ci
USER root
RUN echo "user = www-data" >> /usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf \
 && echo "group = www-data" >> /usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf
