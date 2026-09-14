# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32

ARG TARGETARCH

FROM scratch AS instantclient-amd64

ADD --checksum=sha256:fce485361332927f8328ea4b68d98968c6b0ea124e62470de8c9d0cef880130e \
    https://download.oracle.com/otn_software/linux/instantclient/2326300/instantclient-basic-linux.x64-23.26.3.0.0.zip \
    /tmp/instantclient-basic.zip
ADD --checksum=sha256:7ac13587ba8a734ae7cc06cf42753bbfdbe69839daf87bd5935a49c83decccfd \
    https://download.oracle.com/otn_software/linux/instantclient/2326300/instantclient-sdk-linux.x64-23.26.3.0.0.zip \
    /tmp/instantclient-sdk.zip

FROM scratch AS instantclient-arm64

ADD --checksum=sha256:74b0744d7bf1be28f60c3d90a135e5d9aaca1946bab0adcc0c8db5fbc2cc9758 \
    https://download.oracle.com/otn_software/linux/instantclient/2326300/instantclient-basic-linux.arm64-23.26.3.0.0.zip \
    /tmp/instantclient-basic.zip
ADD --checksum=sha256:5fb03b4615d86ca7a6453a41a334fc27dcac6d839dd7e541177322aaf39ee318 \
    https://download.oracle.com/otn_software/linux/instantclient/2326300/instantclient-sdk-linux.arm64-23.26.3.0.0.zip \
    /tmp/instantclient-sdk.zip

FROM instantclient-${TARGETARCH} AS instantclient

FROM scratch AS composer

ADD --chmod=0755 --checksum=sha256:7a2d379d5b8ffdaa028580ef26494c36d2feef4b178d3dd1473a4dbc5e17c8d6 \
    https://getcomposer.org/download/2.10.3/composer.phar \
    /tmp/composer.phar
ADD --checksum=sha256:2b2df89fb2581e669b4668b451097d4a03f4dc2d7a06df197554064494a90a31 \
    https://raw.githubusercontent.com/composer/composer.github.io/e7f28b7200249f8e5bc912b42837d4598c74153a/snapshots.pub \
    /tmp/keys.dev.pub
ADD --checksum=sha256:d8f3e350437bf3b5342dbf046064ebd1f017ebc720955433194360a01cfd074f \
    https://raw.githubusercontent.com/composer/composer.github.io/e7f28b7200249f8e5bc912b42837d4598c74153a/releases.pub \
    /tmp/keys.tags.pub

FROM scratch AS node-amd64

ADD --checksum=sha256:855d581f8a4eb1a8117e3426de25fe02770592febcfb31369aee1ffbfee9e8ec \
    https://nodejs.org/dist/v24.20.0/node-v24.20.0-linux-x64.tar.gz \
    /tmp/node.tgz

FROM scratch AS node-arm64

ADD --checksum=sha256:3515603e2487879a39bc75716f1a2affd027500c64ba50e845cf72cb33219013 \
    https://nodejs.org/dist/v24.20.0/node-v24.20.0-linux-arm64.tar.gz \
    /tmp/node.tgz

FROM node-${TARGETARCH} AS node

FROM ghcr.io/php/pie:1.4.9-bin@sha256:9fb4fb481767c48f7c57a7fc2c1ccef6ec8fc1e254751a77213cfb0c8f181eba AS pie
FROM docker.io/library/php:8.5-cli-trixie@sha256:9ebdf4c28ab12c02085e171c31e22ac5f7bbb6a9f6927e3bc3dfe7ee23df51e0

COPY --from=composer /tmp/composer.phar /usr/local/bin/composer
COPY --from=node /tmp/node.tgz /tmp/node.tgz
COPY --from=instantclient /tmp/instantclient-basic.zip /tmp/instantclient-basic.zip
COPY --from=instantclient /tmp/instantclient-sdk.zip /tmp/instantclient-sdk.zip

RUN --mount=type=bind,from=pie,source=/pie,target=/usr/local/bin/pie \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --no-install-recommends \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends git libaio1t64 libicu-dev libtool libzip-dev openssh-client python3 sudo unzip zip \
    && unzip -oq /tmp/instantclient-basic.zip -d /opt/oracle \
    && unzip -oq /tmp/instantclient-sdk.zip -d /opt/oracle \
    && ln --symbolic instantclient_23_26 /opt/oracle/instantclient \
    && rm --force -- /tmp/instantclient-basic.zip /tmp/instantclient-sdk.zip \
    && tar --extract --gzip --file /tmp/node.tgz --directory /usr/local --strip-components=1 --exclude='*/README.md' --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' \
    && rm --force -- /tmp/node.tgz \
    && multiarch="$(dpkg-architecture -qDEB_HOST_MULTIARCH)" \
    && ln --symbolic "/usr/lib/${multiarch}/libaio.so.1t64" "/usr/lib/${multiarch}/libaio.so.1" \
    && printf '%s\n' '/opt/oracle/instantclient' > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig \
    && docker-php-ext-install -j"$(nproc)" intl pcntl zip \
    && pie install --no-cache 'oci8/oci8:3.4.1' --with-oci8=instantclient,/opt/oracle/instantclient \
    && pie install --no-cache 'phpredis/phpredis:6.3.0' \
    && pie install --no-cache 'xdebug/xdebug:3.5.3' \
    && cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    && groupadd --gid 1000 devcontainer \
    && useradd --uid 1000 --gid devcontainer --shell /bin/bash --create-home devcontainer \
    && install --directory --owner devcontainer --group devcontainer \
        /home/devcontainer/.composer \
        /home/devcontainer/.local \
        /home/devcontainer/.local/bin \
        /home/devcontainer/.local/lib \
        /home/devcontainer/.local/lib/node_modules \
    && printf '%s\n' 'devcontainer ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/devcontainer \
    && chmod 0440 /etc/sudoers.d/devcontainer \
    && rm -rf /root/.pie /var/lib/apt/lists/*

COPY php/ "$PHP_INI_DIR/conf.d/"
COPY --chown=devcontainer:devcontainer --from=composer /tmp/keys.dev.pub /tmp/keys.tags.pub /home/devcontainer/.composer/

ENV NPM_CONFIG_PREFIX=/home/devcontainer/.local
ENV PATH=/home/devcontainer/.local/bin:${PATH}

USER devcontainer
