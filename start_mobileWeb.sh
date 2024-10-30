#!/bin/bash

sleep 1
source ~/.bashrc
gnome-terminal -- bash -c "cd /home/rainbow/MobileWeb/ && npm run dev; exec bash"

