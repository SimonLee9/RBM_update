#!/bin/bash

# teamviewer 중복  방지를 위해 '리셋'
sudo teamviewer --daemon stop

sudo rm /etc/teamviewer/global.conf
sudo rm -r ~/.config/teamviewer/

sudo teamviewer --daemon start

# 계정 승인이나 다른 작업은 진행해야함

echo "팀뷰어 리셋이 완료되었습니다."

