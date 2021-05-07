#!/bin/bash

# ------------------------------------------------------------------------------
# Starts our Server Instance, once the Ctrl+C has been sent to the container
# the server will shutdown.
# ------------------------------------------------------------------------------

# setup our files
touch log/login-server.log
touch log/map-server.log
touch log/search-server.log

screen -dmS topaz_connect ./topaz_connect --log log/login-server.log &
connect_pid=$!

screen -dmS topaz_search ./topaz_search --log log/search-server.log &
search_pid=$!

screen -dmS topaz_game ./topaz_game --log log/map-server.log &
game_pid=$!

# attach back to the game screen
#screen -R topaz_game
tail -F log/map-server.log log/search-server.log log/login-server.log

# shutdown the instance
screen -S $game_pid.topaz_game -X stuff $'\003\015'
screen -S $search_pid.topaz_search -X stuff $'\003\015'
screen -S $connect_pid.topaz_connect -X stuff $'\003\015'

# EOF
