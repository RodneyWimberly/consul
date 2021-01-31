FROM vault

RUN apk add --no-cache \
    curl \
    jq \
    iputils \
    iproute2 \
    bind-tools \
    gettext

RUN mkdir /usr/local/scripts && \
    mkdir /vault/templates && \
    chown -R vault:vault /usr/local/scripts && \
    chown -R vault:vault /vault/templates

COPY ./core.env /usr/local/scripts/core.env
COPY ./common-functions.sh /usr/local/scripts/common-functions.sh
COPY ./vault-entrypoint.sh /usr/local/scripts/vault-entrypoint.sh
COPY ./vault.json /vault/templates/vault.json

ENTRYPOINT ["/usr/local/scripts/vault-entrypoint.sh"]
CMD [ "server", "-config=/vault/config" ]
