# ------------------------------------------------------------------------------
# Build Stage
# ------------------------------------------------------------------------------

FROM ubuntu:20.04 AS build-stage

# start with setting up new services
WORKDIR /opt

# set the timezone in the container
ENV TZ=America/Chicago

# build arguments for the compile
ARG GIT_REPO=https://github.com/LandSandBoat/server.git
ARG GIT_BRANCH=base
ARG GIT_COMMIT=none

# installation options
ENV INSTALL_DIR=/opt/server

# user set options
ENV TOPAZ_USER=topaz
ENV TOPAZ_GROUP=topaz
ENV TOPAZ_PASSWORD=topaz
ENV TOPAZ_IP=127.0.0.1

# Avoid any UI since we don't have one
ENV DEBIAN_FRONTEND=noninteractive

RUN set -x \
 && echo building with arguments: \
 && echo GIT_REPO=${GIT_REPO} \
 && echo GIT_BRANCH=${GIT_BRANCH} \
 && echo GIT_COMMIT=${GIT_COMMIT}

RUN set -x \
 && apt-get clean \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
    software-properties-common \
    apt-transport-https \
 && add-apt-repository ppa:ubuntu-toolchain-r/test \
 && apt-get update \
 && apt-get install -y \
    wget \
    curl

RUN set -x \
 && wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
 && chmod +x mariadb_repo_setup \
 && ./mariadb_repo_setup \
 && rm mariadb_repo_setup

#libmariadb-dev-compat \

RUN set -x \
 && apt-get clean \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
    software-properties-common \
    apt-transport-https \
 && add-apt-repository ppa:ubuntu-toolchain-r/test \
 && apt-get update \
 && apt-get install -y \
    binutils-dev \
    clang-11 \
    cmake \
    dnsutils \
    git \
    liblua5.1-dev \
    libluajit-5.1-dev \
    libmariadb-dev \
    libssl-dev \
    libzmq3-dev \
    luajit-5.1-dev \
    luarocks \
    make \
    mariadb-server \
    nano \
    net-tools \
    pkg-config \
    python3 \
    python3-pip \
    tzdata \
    zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# Use Clang 11
ENV CC=/usr/bin/clang-11
ENV CXX=/usr/bin/clang++-11

# setup the tools to default to latest verson
RUN set -x \
 && ${CC} --version \
 && ${CXX} --version \
 && python3 --version

# get the Lua BitOp extension installed
RUN set -x \
 && git config --global url.https://github.com/.insteadOf git://github.com/ \
 && luarocks install luabitop

# install TBB (2020.2)
RUN set -x \
 && export CXXFLAGS=" -pthread" \
 && git clone https://github.com/wjakob/tbb.git \
 && cd tbb/build \
 && cmake .. \
 && make -j \
 && make install

# make the instance the new user
RUN set -x \
 && useradd -m ${TOPAZ_USER} --shell=/bin/bash && echo "${TOPAZ_USER}:${TOPAZ_PASSWORD}" | chpasswd \
 && chown -R ${TOPAZ_USER}:${TOPAZ_GROUP} /opt

USER ${TOPAZ_USER}

# establish our checkout of the code (git version)
RUN set -x \
 && export CXXFLAGS=" -pthread" \
 && git clone -b ${GIT_BRANCH} --recursive ${GIT_REPO} \
 && cd ${INSTALL_DIR} \
 && mkdir build \
 && cd build \
 && cmake .. \
 && make -j $(nproc) \
 && cd .. \
 && rm -rf ./build

# create our database (this assumes that the database already exists)


# ------------------------------------------------------------------------------
# Instance Stage
# ------------------------------------------------------------------------------

# generate our instance container
FROM ubuntu:20.04 AS instance

# start with setting up new services
WORKDIR /opt

# set the timezone in the container
ENV TZ=America/Chicago
ENV DEBIAN_FRONTEND="noninteractive"

# build arguments for the instance
ARG GIT_REPO=https://github.com/LandSandBoat/server.git
ARG GIT_BRANCH=base
ARG GIT_COMMIT=none

# installation options
ENV INSTALL_DIR=/opt/server
# user set options
ENV TOPAZ_IP=192.168.2.37
ENV TOPAZ_USER=topaz
ENV TOPAZ_GROUP=topaz
ENV TOPAZ_PASSWORD=topaz
# mysql settings (assumes part of docker-compose)
ENV MYSQL_IP=ffxi-sql
ENV MYSQL_PORT=3306
ENV MYSQL_USER=topazadmin
ENV MYSQL_PASS=topazisawesome
ENV MYSQL_DB=tpzdb

RUN set -x \
 && apt-get clean \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
    apt-transport-https \
 && apt-get update \
 && apt-get install -y \
    wget \
    curl

RUN set -x \
 && wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
 && chmod +x mariadb_repo_setup \
 && ./mariadb_repo_setup \
 && rm mariadb_repo_setup

RUN set -x \
 && apt-get clean \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
    binutils \
    cmake \
    git \
    htop \
    liblua5.1 \
    liblua5.1-dev \
    libluajit-5.1-2 \
    libmariadb-dev \
    libmariadb3 \
    libzmq5 \
    luarocks \
    mariadb-client \
    python3 \
    python3-pip \
    screen \
    tzdata \
    vim \
 && rm -rf /var/lib/apt/lists/*

# get the Lua BitOp extension installed
RUN set -x \
 && git config --global url.https://github.com/.insteadOf git://github.com/ \
 && luarocks install luabitop

# make the instance the new user, and setup folder structure
RUN set -x \
 && useradd -m ${TOPAZ_USER} --shell=/bin/bash && echo "${TOPAZ_USER}:${TOPAZ_PASSWORD}" | chpasswd \
 && mkdir -p ${INSTALL_DIR} \
 && mkdir -p ${INSTALL_DIR}/log \
 && chown -R ${TOPAZ_USER}:${TOPAZ_GROUP} /opt

# change to the proper directory before copying files
WORKDIR ${INSTALL_DIR}

# install TBB (2020.2)
RUN set -x \
 && export CXXFLAGS=" -pthread" \
 && git clone https://github.com/wjakob/tbb.git \
 && cd tbb/build \
 && cmake .. \
 && make -j \
 && make install

# install the topaz package
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/scripts ./scripts
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/modules ./modules
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/sql ./sql
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/tools ./tools
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/xi_connect .
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/xi_map .
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/xi_search .

# some resource files are needed as well
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/compress.dat .
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/decompress.dat .
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/tools/requirements.txt ./requirements.txt

# copy our custom items
COPY --chown=${TOPAZ_USER}:${TOPAZ_GROUP} entry_point.sh ./entry_point.sh
COPY --chown=${TOPAZ_USER}:${TOPAZ_GROUP} load_db.sh ./load_db.sh
COPY --chown=${TOPAZ_USER}:${TOPAZ_GROUP} settings ./settings

USER ${TOPAZ_USER}

# install our python requirements
RUN set -x \
 && pip3 install -r requirements.txt \
 && rm requirements.txt

# update the SQL scripts to work with MySQL 5.7
RUN set -x \
 && sed -i "s/datetime NOT NULL DEFAULT '0000-00-00 00:00:00',/DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,/ig" sql/*.sql \
 && sed -i "s/datetime NOT NULL DEFAULT current_timestamp(),/DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,/ig" sql/*.sql \
 && sed -i "s/DATETIME NOT NULL,/DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,/ig" sql/*.sql \
 && sed -i "s|blob DEFAULT 0|blob DEFAULT NULL|ig" sql/*.sql

# set the version numbergit
RUN set -x \
 && export commit_version=$(git ls-remote ${GIT_REPO} refs/heads/${GIT_BRANCH} | cut -c1-10) \
 && export time_stamp=$(date +%Y%m%d) \
 && sed -i "s|%date%|[${commit_version}] (${time_stamp})|g" settings/default/main.lua

# set the volumes available
VOLUME [ "/opt/server/settings", "/opt/server/log" ]

# make our ports available
EXPOSE 54230/tcp
EXPOSE 54231/tcp
EXPOSE 54001/tcp
EXPOSE 54002/tcp

EXPOSE 54230/udp

ENTRYPOINT [ "/opt/server/entry_point.sh" ]
CMD [ "server" ]

# captures the latest commit ID with respect to this branch
#  (provides frist 10 characters)
# git ls-remote https://github.com/project-topaz/topaz refs/heads/trust | cut -c1-10

# EOF
