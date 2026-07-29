# syntax=docker/dockerfile:1

FROM docker.io/library/composer:2 AS versionedcomposer
FROM docker.io/library/php:8.5-fpm-trixie AS versionedphp

FROM docker.io/library/busybox:latest AS instantclient
ADD --checksum=sha256:d6715e404a35b3a538280b78df6f7ee59da83a9d36b596218fd264051db977f3 https://download.oracle.com/otn_software/linux/instantclient/2326100/instantclient-basic-linux.x64-23.26.1.0.0.zip /tmp/instantclient-basic.zip
ADD --checksum=sha256:2d7ef8ec14c3e0240221620c12ce94d047092c9065171db17778cce7b1fdd5db https://download.oracle.com/otn_software/linux/instantclient/2326100/instantclient-sdk-linux.x64-23.26.1.0.0.zip /tmp/instantclient-sdk.zip
RUN <<EOF
  set -eu
  mkdir -p /opt/oracle
  unzip -oq /tmp/instantclient-basic.zip -d /opt/oracle
  unzip -oq /tmp/instantclient-sdk.zip -d /opt/oracle
  mv /opt/oracle/instantclient_23_26 /opt/oracle/instantclient
EOF

FROM versionedphp AS base
WORKDIR /var/www/html
ENV APP_ENV=production
ENV NODE_ENV=production
COPY --from=instantclient /opt/oracle/instantclient /opt/oracle/instantclient
RUN <<EOF
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get upgrade -y --no-install-recommends
  apt-get install -y --no-install-recommends libaio1t64
  ln -sfn /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1
  echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf
  ldconfig
  pecl channel-update pecl.php.net
  printf 'instantclient,/opt/oracle/instantclient\n' | pecl install oci8
  pecl install apcu redis
  docker-php-ext-enable oci8 apcu redis
  rm -rf /opt/oracle/instantclient/sdk /tmp/pear
  apt-get autoremove -y
  apt-get autoclean -y
  apt-get clean -y
  rm -rf /var/lib/apt/lists/*
EOF
COPY --from=versionedcomposer /usr/bin/composer /usr/bin/composer

FROM base AS devcontainer
ENV APP_ENV=local
ENV NODE_ENV=development
RUN <<EOF
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive
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
  install -d -o devcontainer -g devcontainer /home/devcontainer/.composer/cache /home/devcontainer/.npm
  wget https://nodejs.org/dist/v24.18.0/node-v24.18.0-linux-x64.tar.xz -O node.tar.xz
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
