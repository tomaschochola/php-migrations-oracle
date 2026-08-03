# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

ARG TARGETARCH

FROM docker.io/library/busybox:1.37.0@sha256:9db7b59979c38555a39def84a31fb98b5296952f9e3afd4f6f11f05b07adfab0 AS versionedinstantclient-amd64

ADD --checksum=sha256:fce485361332927f8328ea4b68d98968c6b0ea124e62470de8c9d0cef880130e \
    https://download.oracle.com/otn_software/linux/instantclient/2326300/instantclient-basic-linux.x64-23.26.3.0.0.zip \
    /tmp/instantclient-basic.zip
ADD --checksum=sha256:7ac13587ba8a734ae7cc06cf42753bbfdbe69839daf87bd5935a49c83decccfd \
    https://download.oracle.com/otn_software/linux/instantclient/2326300/instantclient-sdk-linux.x64-23.26.3.0.0.zip \
    /tmp/instantclient-sdk.zip

FROM docker.io/library/busybox:1.37.0@sha256:9db7b59979c38555a39def84a31fb98b5296952f9e3afd4f6f11f05b07adfab0 AS versionedinstantclient-arm64

ADD --checksum=sha256:74b0744d7bf1be28f60c3d90a135e5d9aaca1946bab0adcc0c8db5fbc2cc9758 \
    https://download.oracle.com/otn_software/linux/instantclient/2326300/instantclient-basic-linux.arm64-23.26.3.0.0.zip \
    /tmp/instantclient-basic.zip
ADD --checksum=sha256:5fb03b4615d86ca7a6453a41a334fc27dcac6d839dd7e541177322aaf39ee318 \
    https://download.oracle.com/otn_software/linux/instantclient/2326300/instantclient-sdk-linux.arm64-23.26.3.0.0.zip \
    /tmp/instantclient-sdk.zip

FROM versionedinstantclient-${TARGETARCH} AS versionedinstantclient

RUN mkdir -p /opt/oracle \
    && unzip -oq /tmp/instantclient-basic.zip -d /opt/oracle \
    && unzip -oq /tmp/instantclient-sdk.zip -d /opt/oracle \
    && mv /opt/oracle/instantclient_23_26 /opt/oracle/instantclient

FROM docker.io/library/composer:2@sha256:4d71c3c2109c61d5415544264b59ad4087e4c5b7244481723664138fd36d5040 AS versionedcomposer
FROM docker.io/library/node:24-trixie@sha256:dfa43abae25030f5456007944f725379d1f5be4bb723bd501ac39ac72ffa5474 AS versionednode
FROM ghcr.io/php/pie:1.4.5-bin@sha256:14bc484d9be70396e31b0b57222724f780fe91f76aa5294304086dbce386c044 AS versionedpie
FROM docker.io/library/php:8.5-cli-trixie@sha256:f5d2b71350cdc3c2fc807d6679f5bdac2898d7558945105e46308e4659fb37ac

COPY --from=versionedcomposer /usr/bin/composer /usr/local/bin/composer
COPY --from=versionednode /usr/local/bin/node /usr/local/bin/node
COPY --from=versionednode /usr/local/include/node /usr/local/include/node
COPY --from=versionednode /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=versionednode /usr/local/LICENSE /usr/local/share/doc/node/LICENSE
COPY --from=versionedinstantclient /opt/oracle/instantclient /opt/oracle/instantclient

RUN --mount=type=bind,from=versionedpie,source=/pie,target=/usr/local/bin/pie \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --no-install-recommends \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends git libaio1t64 libicu-dev libtool libzip-dev openssh-client python3 sudo unzip zip \
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
    && ln --symbolic ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln --symbolic ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && rm -rf /root/.pie /var/lib/apt/lists/*

COPY php/ "$PHP_INI_DIR/conf.d/"
COPY --chown=devcontainer:devcontainer --from=versionedcomposer /tmp/keys.dev.pub /tmp/keys.tags.pub /home/devcontainer/.composer/

ENV NPM_CONFIG_PREFIX=/home/devcontainer/.local
ENV PATH=/home/devcontainer/.local/bin:${PATH}

USER devcontainer
