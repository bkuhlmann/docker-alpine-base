# syntax=docker/dockerfile:1.3-labs

FROM alpine:3.18.5

LABEL description="Alchemists Alpine Base"
LABEL maintainer="brooke@alchemists.io"

ENV IMAGE_GIT_VERSION=2.43.0

ARG USER_ID=1000
ARG USER_NAME=engineer
ARG GROUP_ID=$USER_ID
ARG GROUP_NAME=engineers

RUN <<STEPS
  addgroup -g $GROUP_ID $GROUP_NAME
  adduser -u $USER_ID -G $GROUP_NAME -D -g "" -s /bin/bash $USER_NAME $GROUP_NAME
STEPS

WORKDIR /usr/src

RUN <<STEPS
  # Defaults
  set -o nounset
  set -o errexit
  set -o pipefail
  IFS=$'\n\t'

  # Setup
  apk update
  apk upgrade --available
  apk add --no-cache \
          ca-certificates \
          bash \
          curl \
          gnupg \
          openssl \
          openssh \
          vim
  apk add --no-cache --update bash
  apk add --no-cache \
          --virtual .git-build-dependencies \
          build-base \
          curl-dev \
          tcl \
          zlib-dev

  # Download
  curl --remote-name https://mirrors.edge.kernel.org/pub/software/scm/git/git-$IMAGE_GIT_VERSION.tar.gz
  curl --remote-name https://mirrors.edge.kernel.org/pub/software/scm/git/git-$IMAGE_GIT_VERSION.tar.sign
  gunzip git-$IMAGE_GIT_VERSION.tar.gz
  rm -f git-$IMAGE_GIT_VERSION.tar.sign
  tar --extract --verbose --file git-$IMAGE_GIT_VERSION.tar

  # Build
  cd git-$IMAGE_GIT_VERSION
  ./configure
  make prefix=/usr all
  make INSTALL_STRIP=-s prefix=/usr install

  # Clean
  cd ..
  rm -rf git-$IMAGE_GIT_VERSION
  rm -f git-$IMAGE_GIT_VERSION.tar
  apk del .git-build-dependencies

  # Test
  git --version
  gpg --version
  openssl version
STEPS

RUN <<STEPS
  git config --global init.defaultBranch main
  git config --global user.name "Test User"
  git config --global user.email "test@example.com"
STEPS

ENV EDITOR=vim
ENV TERM=xterm
