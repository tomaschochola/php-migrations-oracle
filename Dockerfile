# syntax=docker/dockerfile:1

ARG PHP_VERSION=8.5-fpm-trixie
ARG COMPOSER_VERSION=2

FROM composer:2 AS versionedcomposer
FROM php:8.5-fpm-trixie AS versionedphp

FROM versionedphp AS base
WORKDIR /var/www/html
ENV APP_ENV=production
ENV NODE_ENV=production
RUN <<EOF
  set -euo pipefail
  apt-get update -y
  apt-get upgrade -y --no-install-recommends
  pecl channel-update pecl.php.net
  pecl install apcu redis
  docker-php-ext-enable apcu redis
  apt-get autoremove -y
  apt-get autoclean -y
  apt-get clean -y
  rm -rf /var/lib/apt/lists/*
EOF
COPY --from=versionedcomposer /usr/bin/composer /usr/bin/composer

FROM base AS devcontainer
ENV APP_ENV=local
ENV NODE_ENV=development
ADD --chmod=755 https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 /usr/local/bin/yq
RUN <<EOF
  set -euo pipefail
  apt-get update -y
  apt-get upgrade -y --no-install-recommends
  apt-get install -y --no-install-recommends ca-certificates curl wget build-essential git zip unzip
  docker-php-ext-install pcntl
  pecl install xdebug
  docker-php-ext-enable xdebug
  apt-get install -y --no-install-recommends libzip-dev
  docker-php-ext-install zip
  apt-get install -y --no-install-recommends libicu-dev
  docker-php-ext-install intl
  mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
  groupadd devcontainer
  useradd -s /bin/bash --gid devcontainer -m devcontainer
  wget https://nodejs.org/dist/v24.14.0/node-v24.14.0-linux-x64.tar.xz -O node.tar.xz
  tar -xf node.tar.xz -C /usr/local --strip-components=1
  rm node.tar.xz
  apt-get autoremove -y
  apt-get autoclean -y
  apt-get clean -y
  rm -rf /var/lib/apt/lists/*
EOF
COPY ./ops/php/z.ini /usr/local/etc/php/conf.d/z.ini
COPY ./ops/php/zz.ini /usr/local/etc/php/conf.d/zz.ini
COPY ./ops/php/zzz.ini /usr/local/etc/php/conf.d/zzz.ini
USER devcontainer
