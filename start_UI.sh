#!/bin/bash

sleep 1
source ~/.bashrc
gnome-terminal -- bash -c "cd /home/rainbow/RBM-S100-release/ && RBM_S100_NewUI; exec bash"
