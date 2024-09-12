#!/bin/bash

sleep 1
source ~/.bashrc
#find / -name "libOrbbecSDK.so.1.10"
export LD_LIBRARY_PATH=/home/rainbow/OrbbecSDK/lib/linux_x64/:$LD_LIBRARY_PATH


gnome-terminal -- bash -c "cd /home/rainbow/RBM-S100-release/ && ./SLAMNAV2; exec bash"
