#!/bin/bash

# 패키지 리스트 업데이트
sudo apt-get update

# 팀뷰어 설치 파일을 Home 경로에 다운로드
#wget -P ~/ https://download.teamviewer.com/download/linux/teamviewer_arm64.deb
wget -P ~/ https://download.teamviewer.com/download/linux/teamviewer-host_arm64.deb

# 다운로드한 설치 파일을 이용하여 팀뷰어 설치
sudo apt install ~/teamviewer-host_arm64.deb -y

