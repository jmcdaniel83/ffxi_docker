# ------------------------------------------------------------------------------
# Build Stage
# ------------------------------------------------------------------------------

FROM debian:10.4 AS build-stage

# start with setting up new services
WORKDIR /opt

# set the timezone in the container
COPY Chicago /etc/localtime

# build arguments for the compile
ARG GIT_REPO=https://github.com/project-topaz/topaz.git
ARG GIT_VERSION=trust

# installation options
ENV INSTALL_DIR=/opt/topaz
# user set options
ENV TOPAZ_USER=topaz
ENV TOPAZ_GROUP=topaz
ENV TOPAZ_PASSWORD=topaz
ENV TOPAZ_IP=127.0.0.1

RUN set -x \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
    apt-transport-https \
 && apt-get update \
 && apt-get install -y \
    autoconf \
    build-essential \
    gcc \
    git \
    htop \
    liblua5.1-dev \
    libmariadb-dev \
    libmariadb-dev-compat \
    libmariadbclient-dev \
    libssl-dev \
    libzmq3-dev \
    lua5.1 \
    luajit \
    luarocks \
    mariadb-client \
    mariadb-server \
    nano \
    pkg-config \
    screen \
 && rm -rf /var/lib/apt/lists/*

# get the Lua BitOp extension installed
RUN set -x \
 && luarocks install luabitop

# make the instance the new user
RUN set -x \
 && useradd -m ${TOPAZ_USER} --shell=/bin/bash && echo "${TOPAZ_USER}:${TOPAZ_PASSWORD}" | chpasswd \
 && chown -R ${TOPAZ_USER}:${TOPAZ_GROUP} /opt

USER ${TOPAZ_USER}

# establish our checkout of the code (git version)
RUN set -x \
 && git clone -b ${GIT_VERSION} --recursive ${GIT_REPO} \
 && cd ${INSTALL_DIR} \
 && sh autogen.sh \
 && ./configure CXXFLAGS=" -pthread" \
 && make -j $(nproc)

# create our database (this assumes that the database already exists)


# ------------------------------------------------------------------------------
# Instance Stage
# ------------------------------------------------------------------------------

# generate our instance container
FROM debian:10.4 AS instance

# start with setting up new services
WORKDIR /opt

# set the timezone in the container
COPY Chicago /etc/localtime

# build arguments for the instance
ARG GIT_REPO=https://github.com/project-topaz/topaz.git
ARG GIT_VERSION=trust

# installation options
ENV INSTALL_DIR=/opt/topaz
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
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
    git \
    htop \
    liblua5.1 \
    libmariadb3 \
    libzmq5 \
    luarocks \
    screen \
    vim \
 && rm -rf /var/lib/apt/lists/*

# get the Lua BitOp extension installed
RUN set -x \
 && luarocks install luabitop

# make the instance the new user, and setup folder structure
RUN set -x \
 && useradd -m ${TOPAZ_USER} --shell=/bin/bash && echo "${TOPAZ_USER}:${TOPAZ_PASSWORD}" | chpasswd \
 && mkdir -p ${INSTALL_DIR} \
 && mkdir -p ${INSTALL_DIR}/log \
 && chown -R ${TOPAZ_USER}:${TOPAZ_GROUP} /opt

# change to the proper directory before copying files
WORKDIR ${INSTALL_DIR}

# install the topaz package
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/scripts ./scripts
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/sql ./sql
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/conf/default ./conf
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/topaz_connect .
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/topaz_game .
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/topaz_search .

# some resource files are needed as well
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/compress.dat .
COPY --from=build-stage --chown=${TOPAZ_USER}:${TOPAZ_GROUP} ${INSTALL_DIR}/decompress.dat .

# copy our custom items
COPY --chown=${TOPAZ_USER}:${TOPAZ_GROUP} entry_point.sh ${INSTALL_DIR}/entry_point.sh
COPY --chown=${TOPAZ_USER}:${TOPAZ_GROUP} load_db.sh ${INSTALL_DIR}/load_db.sh
COPY --chown=${TOPAZ_USER}:${TOPAZ_GROUP} server_message.conf ./conf/server_message.conf

USER ${TOPAZ_USER}

# setting up the configuration
RUN set -x \
 && sed -i 's/mysql_host:      127.0.0.1/mysql_host:      '${MYSQL_IP}'/g' conf/*.conf \
 && sed -i 's/mysql_port:      3306/mysql_port:      '${MYSQL_PORT}'/g' conf/*.conf \
 && sed -i 's/mysql_login:     root/mysql_login:     '${MYSQL_USER}'/g' conf/*.conf \
 && sed -i 's/mysql_password:  root/mysql_password:  '${MYSQL_PASS}'/g' conf/*.conf \
 && sed -i 's/mysql_database:  tpzdb/mysql_database:  '${MYSQL_DB}'/g' conf/*.conf

# update the SQL scripts to work with MySQL 5.7
RUN set -x \
 && sed -i "s/datetime NOT NULL DEFAULT '0000-00-00 00:00:00',/DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,/ig" sql/*.sql \
 && sed -i "s/datetime NOT NULL DEFAULT current_timestamp(),/DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,/ig" sql/*.sql \
 && sed -i "s/DATETIME NOT NULL,/DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,/ig" sql/*.sql

# update the timestamp format for the logs
RUN set -x \
 && sed -i 's|\[%d/%b %H\:%M\]|[%Y%m%d_%H%M%S]|g' conf/*.conf \
 && sed -i 's|\[%d/%b\] \[%H\:%M\:%S\]|[%Y%m%d_%H%M%S]|g' conf/*.conf 

# set the version numbergit
RUN set -x \
 && git ls-remote ${GIT_REPO} refs/heads/${GIT_VERSION} | cut -c1-10 \
 && export time_stamp=$(date +%Y%m%d) \
 && sed -i 's/%date%/'${time_stamp}'/g' conf/server_message.conf

# set the volumes available
VOLUME [ "/opt/topaz/conf", "/opt/topaz/log" ]

# make our ports available
EXPOSE 54230/tcp
EXPOSE 54231/tcp
EXPOSE 54001/tcp
EXPOSE 54002/tcp

EXPOSE 54230/udp

ENTRYPOINT [ "/opt/topaz/entry_point.sh" ]
CMD [ "server" ]

# captures the latest commit ID with respect to this branch
#  (provides frist 10 characters)
# git ls-remote https://github.com/project-topaz/topaz refs/heads/trust | cut -c1-10

# EOF
