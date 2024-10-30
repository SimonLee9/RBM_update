#!/bin/bash

sleep 1
source ~/.bashrc


export LD_LIBRARY_PATH=/home/rainbow/OrbbecSDK/lib/linux_x64/:$LD_LIBRARY_PATH
#gnome-terminal -- bash -c "cd /home/rainbow/RBM-S100-release/ && ./SLAMNAV2; exec bash"

gnome-terminal -- bash -c "cd /home/slamnav2_s100/slamnav2/ && ./SLAMNAV2; exec bash"
