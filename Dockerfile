FROM alpine:3.13.4

LABEL description="Alchemists Alpine Base"
LABEL maintainer="brooke@alchemists.io"

ENV IMAGE_GIT_VERSION=2.31.1

ARG USER_ID=1000
ARG USER_NAME=engineer
ARG GROUP_ID=$USER_ID
ARG GROUP_NAME=engineers

RUN addgroup -g $GROUP_ID $GROUP_NAME \
    && adduser -u $USER_ID -G $GROUP_NAME -D -g "" -s /bin/bash $USER_NAME $GROUP_NAME

WORKDIR /usr/src

RUN set -o nounset \
    && set -o errexit \
    && set -o pipefail \
    && IFS=$'\n\t' \
    && apk update \
    && apk upgrade --available \
    && apk add --no-cache \
               ca-certificates \
               bash \
               curl \
               gnupg \
               openssl \
               openssh \
               vim \
    && apk add --no-cache \
               --update bash \
    && apk add --no-cache \
               --virtual .git-build-dependencies \
               build-base \
               curl-dev \
               tcl \
               zlib-dev \
    && curl --remote-name https://mirrors.edge.kernel.org/pub/software/scm/git/git-$IMAGE_GIT_VERSION.tar.gz \
    && curl --remote-name https://mirrors.edge.kernel.org/pub/software/scm/git/git-$IMAGE_GIT_VERSION.tar.sign \
    && gpg --recv-keys 96E07AF25771955980DAD10020D04E5A713660A7 \
    && gunzip git-$IMAGE_GIT_VERSION.tar.gz \
    && gpg --verify git-$IMAGE_GIT_VERSION.tar.sign git-$IMAGE_GIT_VERSION.tar \
    && rm -f git-$IMAGE_GIT_VERSION.tar.sign \
    && tar --extract --verbose --file git-$IMAGE_GIT_VERSION.tar \
    && cd git-$IMAGE_GIT_VERSION \
    && ./configure \
    && make prefix=/usr all \
    && make prefix=/usr install \
    && cd .. \
    && rm -rf git-$IMAGE_GIT_VERSION \
    && rm -f git-$IMAGE_GIT_VERSION.tar \
    && apk del .git-build-dependencies

RUN git config --global init.defaultBranch main

COPY .config/docker-alpine-base/shell_loader.sh /etc/profile.d/

ENV EDITOR=vim
ENV TERM=xterm
