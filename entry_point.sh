#!/bin/bash

# ------------------------------------------------------------------------------
# Starts our Server Instance, once the Ctrl+C has been sent to the container
# the server will shutdown.
# ------------------------------------------------------------------------------

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap "echo shutting down..." HUP INT QUIT TERM

CONNECT_LOG=log/login-server.log
SEARCH_LOG=log/search-server.log
GAME_LOG=log/map-server.log

CONNECT_PID=''
SEARCH_PID=''
GAME_PID=''

function init {
   if [ ! -d "/opt/topaz.trust/log" ]; then
      makedir -p /opt/topaz.trust/log
   fi

   # make sure that the files exist for our logs
   touch ${CONNECT_LOG}
   touch ${SEARCH_LOG}
   touch ${GAME_LOG}
}

function start_server {
   # run our screens for the server
   screen -dmS topaz_connect ./topaz_connect --log ${CONNECT_LOG} &
   CONNECT_PID=$!

   screen -dmS topaz_search ./topaz_search --log ${SEARCH_LOG} &
   SEARCH_PID=$!

   screen -dmS topaz_game ./topaz_game --log ${GAME_LOG} &
   GAME_PID=$!
}

function stop_server {
   ## provides a <ctrl+c> <enter> to the screens
   # using the PIDs stored, will shutdown our instances
   echo Shutting down game...
   #screen -S ${GAME_PID}.topaz_game -X stuff $'\003\015'
   screen -S topaz_game -X stuff $'\003\015'

   echo Shutting down search...
   #screen -S ${SEARCH_PID}.topaz_search -X stuff $'\003\015'
   screen -S topaz_search -X stuff $'\003\015'

   echo Shutting down connect...
   #screen -S ${CONNECT_PID}.topaz_connect -X stuff $'\003\015'
   screen -S topaz_connect -X stuff $'\003\015'
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
