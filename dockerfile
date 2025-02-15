ARG BUILDPLATFORM
FROM alpine:3.20

ENV BUILD_DEPS="gettext"  \
    RUNTIME_DEPS="libintl"

RUN apk add --no-cache $RUNTIME_DEPS && \
    apk add --no-cache --virtual .build-deps $BUILD_DEPS && \
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    apk del .build-deps

RUN apk add --no-cache jq curl

WORKDIR /home/argocd/cmp-server/config/
COPY plugin.yaml ./

CMD ["/bin/sh"]
