#!/bin/bash

# ------------------------------------------------------------------------------
# Starts our Server Instance, once the Ctrl+C has been sent to the container
# the server will shutdown.
# ------------------------------------------------------------------------------

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap "echo shutting down..." HUP INT QUIT TERM

INSTALL_DIR='/opt/server'

CONNECT_LOG=log/login-server.log
SEARCH_LOG=log/search-server.log
GAME_LOG=log/map-server.log

CONNECT_PID=''
SEARCH_PID=''
GAME_PID=''

function init {
   if [ ! -d "${INSTALL_DIR}/log" ]; then
      mkdir -p ${INSTALL_DIR}/log
   fi

   # make sure that the files exist for our logs
   set -x \
    && touch ${CONNECT_LOG} \
    && touch ${SEARCH_LOG} \
    && touch ${GAME_LOG}
}

function start_server {
   # run our screens for the server
   screen -dmS xi_connect ./xi_connect --log ${CONNECT_LOG} &
   CONNECT_PID=$!

   screen -dmS xi_search ./xi_search --log ${SEARCH_LOG} &
   SEARCH_PID=$!

   screen -dmS xi_map ./xi_map --log ${GAME_LOG} &
   GAME_PID=$!

}

function stop_server {
   ## provides a <ctrl+c> <enter> to the screens
   echo Shutting down game...
   screen -S xi_map -X stuff $'\003\015'

   echo Shutting down search...
   screen -S xi_search -X stuff $'\003\015'

   echo Shutting down connect...
   screen -S xi_connect -X stuff $'\003\015'
}

if [ "$1" = 'server' ]; then
   init
   start_server

   # watch the logs that are generated
   tail -F log/*.log

   stop_server
else
   exec "$@"
fi

# EOF
