#!/bin/bash

# All repo update

# 0. RBM_update
git pull #현재 경로 : RBM_update

# 1. web_robot_ui 
cd web_robot_ui #현재 경로 : web_robot_ui 

git pull https://github.com/rainbow-mobile/web_robot_ui.git


# 2. web_robot_server
cd web_robot_server #현재 경로 : web_robot_server

git clone https://github.com/rainbow-mobile/web_robot_server.git


# 3. Taskman

# 4. slamnav2

# 5. ui (for s100)
