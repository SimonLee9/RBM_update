#!/bin/bash

sleep 1
source ~/.bashrc
gnome-terminal -- bash -c "cd /home/rainbow/MobileServer/ && node ./src/server.js; exec bash"

