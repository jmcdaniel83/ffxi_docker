#!/bin/bash

apt update

apt upgrade -y

apt install -y \
  net-tools \
  nano \
  software-properties-common \
  git \
  clang-11 \
  cmake \
  make \
  libluajit-5.1-dev \
  libzmq3-dev \
  libssl-dev \
  zlib1g-dev \
  mariadb-server \
  libmariadb-dev \
  luarocks

# EOF

