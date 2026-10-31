# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

ARG TARGETARCH

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

FROM scratch AS instantclient-amd64

ADD --checksum=sha256:cab59aa3b411b3b50898e456fa9aabfe48d67e25cbc1bb23303800390ce7de26 \
    https://download.oracle.com/otn_software/linux/instantclient/2326400/instantclient-basic-linux.x64-23.26.4.0.0.zip \
    /tmp/instantclient-basic.zip

ADD --checksum=sha256:75b7b72c378693eca8f3e0502f2d035612baec43be1e75760839cc87c437fb01 \
    https://download.oracle.com/otn_software/linux/instantclient/2326400/instantclient-sdk-linux.x64-23.26.4.0.0.zip \
    /tmp/instantclient-sdk.zip

FROM scratch AS instantclient-arm64

ADD --checksum=sha256:688df426cabb4e5945e8409ae022acd16b92ff06582c8d93af2f41e3fb9a42f3 \
    https://download.oracle.com/otn_software/linux/instantclient/2326400/instantclient-basic-linux.arm64-23.26.4.0.0.zip \
    /tmp/instantclient-basic.zip

ADD --checksum=sha256:8a7797a5cc72392eb453f28dd5329ae23133cefd51915147cf6631812684a7b2 \
    https://download.oracle.com/otn_software/linux/instantclient/2326400/instantclient-sdk-linux.arm64-23.26.4.0.0.zip \
    /tmp/instantclient-sdk.zip

FROM instantclient-${TARGETARCH} AS instantclient

FROM scratch AS node-amd64

ADD --checksum=sha256:5848553868b402d3fabb5b09270649977780a390f832155721025a08b5104455 \
    https://nodejs.org/dist/v26.13.0/node-v26.13.0-linux-x64.tar.gz \
    /tmp/node.tgz

FROM scratch AS node-arm64

ADD --checksum=sha256:439e9c438acdf6a6ffe47418da709153d66c4bed812e30a473faacb107dd2791 \
    https://nodejs.org/dist/v26.13.0/node-v26.13.0-linux-arm64.tar.gz \
    /tmp/node.tgz

FROM node-${TARGETARCH} AS node

FROM ghcr.io/php/pie:1.5.3-bin@sha256:9d3e6d9dafa5ae8cf034489260e206a5aa1b488b29c0ddaea9149826d9e32f52 AS pie

FROM docker.io/library/php:8.5.12-cli-trixie@sha256:635a4b998025ab269194639a5549c6fdcd9b4f88ec8cd761b092de8653d40663

COPY --from=composer /tmp/composer.phar /usr/local/bin/composer
COPY --from=instantclient /tmp/instantclient-basic.zip /tmp/instantclient-basic.zip
COPY --from=instantclient /tmp/instantclient-sdk.zip /tmp/instantclient-sdk.zip
COPY --from=node /tmp/node.tgz /tmp/node.tgz

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --no-install-recommends \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends ca-certificates fd-find git libaio1t64 libatomic1 libicu-dev libtool libzip-dev make openssh-client python3 sudo unzip zip \
    && tar --extract --gzip --file /tmp/node.tgz --directory /usr/local --strip-components=1 --no-same-owner --exclude='*/README.md' --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' \
    && ln --symbolic /usr/bin/fdfind /usr/local/bin/fd \
    && ln --symbolic /usr/local/bin/node /usr/local/bin/nodejs \
    && rm --force -- /tmp/node.tgz \
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
    && rm -rf /var/lib/apt/lists/*

RUN npm install --global --prefix=/usr/local --ignore-scripts npm@12.2.1 \
    && rm -rf /root/.npm

RUN --mount=type=bind,from=pie,source=/pie,target=/usr/local/bin/pie \
    unzip -oq /tmp/instantclient-basic.zip -d /opt/oracle \
    && unzip -oq /tmp/instantclient-sdk.zip -d /opt/oracle \
    && ln --symbolic instantclient_23_26 /opt/oracle/instantclient \
    && rm --force -- /tmp/instantclient-basic.zip /tmp/instantclient-sdk.zip \
    && multiarch="$(dpkg-architecture -qDEB_HOST_MULTIARCH)" \
    && ln --symbolic "/usr/lib/${multiarch}/libaio.so.1t64" "/usr/lib/${multiarch}/libaio.so.1" \
    && printf '%s\n' '/opt/oracle/instantclient' > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig \
    && docker-php-ext-install -j"$(nproc)" intl pcntl zip \
    && pie install --no-cache 'oci8/oci8:3.4.1' --with-oci8=instantclient,/opt/oracle/instantclient \
    && pie install --no-cache 'phpredis/phpredis:6.3.0' \
    && pie install --no-cache 'xdebug/xdebug:3.5.3' \
    && cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    && rm -rf /root/.pie

COPY php/ "$PHP_INI_DIR/conf.d/"
COPY --chown=devcontainer:devcontainer --from=composer /tmp/keys.dev.pub /tmp/keys.tags.pub /home/devcontainer/.composer/

ENV NPM_CONFIG_PREFIX=/home/devcontainer/.local
ENV PATH=/home/devcontainer/.local/bin:${PATH}

USER devcontainer
