# syntax = docker/dockerfile:1.4

FROM alpine:3.24.1

LABEL description="Alchemists Alpine Base"
LABEL maintainer="Brooke Kuhlmann <brooke@alchemists.io>"

ARG GIT_VERSION=2.55.0
ARG RUSTUP_VERISON=1.29.0
ARG RUST_TOOLCHAIN_VERSION=1.91.1

RUN apk add --no-cache bash

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

RUN <<STEPS
  # Install
  apk update
  apk upgrade --available
  apk add --no-cache \
          ca-certificates \
          curl \
          gcc \
          gnupg \
          openssh \
          openssl \
          vim
  apk add --no-cache --update bash
  apk add --no-cache \
          --virtual .build-dependencies \
          build-base \
          coreutils \
          curl-dev \
          linux-headers \
          tcl \
          xz \
          zlib-dev

  # Rust (install)
  rustArch=
  apkArch="$(apk --print-arch)"
  case "$apkArch" in
    'x86_64')
      rustArch="x86_64-unknown-linux-musl"
      rustupUrl="https://static.rust-lang.org/rustup/archive/$RUSTUP_VERISON/x86_64-unknown-linux-musl/rustup-init"
      ;;
    'aarch64')
      rustArch="aarch64-unknown-linux-musl"
      rustupUrl="https://static.rust-lang.org/rustup/archive/$RUSTUP_VERISON/aarch64-unknown-linux-musl/rustup-init"
      ;;
  esac;

  if [ -n "$rustArch" ]; then
    mkdir -p /tmp/rust
    curl --fail --silent --show-error --location --output /tmp/rust/rustup-init "$rustupUrl"
    curl --fail \
         --silent \
         --show-error \
         --location \
         --output /tmp/rust/rustup-init.sha256 "${rustupUrl}.sha256"
    echo "$(awk '{print $1}' /tmp/rust/rustup-init.sha256) /tmp/rust/rustup-init" \
         | sha256sum --check --strict
    chmod +x /tmp/rust/rustup-init
    export RUSTUP_HOME="/tmp/rust/rustup" CARGO_HOME="/tmp/rust/cargo"
    export PATH="$CARGO_HOME/bin:$PATH"
    /tmp/rust/rustup-init -y \
                          --no-modify-path \
                          --profile minimal \
                          --default-toolchain "$RUST_TOOLCHAIN_VERSION" \
                          --default-host "$rustArch"
    rustc --version
    cargo --version
  fi;

  # Git (download)
  curl --remote-name https://www.kernel.org/pub/software/scm/git/git-$GIT_VERSION.tar.xz
  curl --remote-name https://www.kernel.org/pub/software/scm/git/git-$GIT_VERSION.tar.sign

  # Git (verify, uses core maintainer Junio C Hamano's signing key)
  xz --decompress git-$GIT_VERSION.tar.xz
  gpg --keyserver keyserver.ubuntu.com --recv-keys 20D04E5A713660A7
  gpg --verify git-$GIT_VERSION.tar.sign git-$GIT_VERSION.tar

  # Git (build)
  tar --extract --verbose --file git-$GIT_VERSION.tar
  (
    cd git-$GIT_VERSION || exit
    ./configure
    make prefix=/usr all
    make INSTALL_STRIP=-s prefix=/usr install
  )

  # Git (clean)
  rm -rf git-$GIT_VERSION
  rm -f git-$GIT_VERSION.tar
  rm -f git-$GIT_VERSION.tar.sign
  apk del .build-dependencies

  # Test
  git --version
  gpg --version
  openssl version
STEPS

RUN <<STEPS
  git config set --global init.defaultBranch main
  git config set --global user.name "Test User"
  git config set --global user.email "test@example.com"

  addgroup -g 1000 app
  adduser -u 1000 -G app -D -g "" -s /bin/bash app app
STEPS

ENV EDITOR=vim
ENV TERM=xterm
