FROM --platform=$BUILDPLATFORM alpine:3.20

ARG BUILDPLATFORM

ENV BUILD_DEPS="gettext"  \
    RUNTIME_DEPS="libintl"


#Install envsubst, jq and curl     
RUN set -x && \
    apk add --update $RUNTIME_DEPS && \
    apk add --virtual build_deps $BUILD_DEPS &&  \
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    apk del build_deps
RUN apk --update add jq 
RUN apk --update add curl

WORKDIR /home/argocd/cmp-server/config/
COPY plugin.yaml ./

CMD ["/bin/sh"]
