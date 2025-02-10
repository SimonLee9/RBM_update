#!/bin/bash

sleep 3
#source ~/.bashrc

export LD_LIBRARY_PATH=/home/rainbow/slamnav2/:$LD_LIBRARY_PATH


gnome-terminal -- bash -c "cd /home/rainbow/robot_ui/ && ./RBM_S100_NewUI; exec bash"
