#!/bin/bash

# Ultra에서 기존 UI_MOBILE_TEMP를 실행하기 위한 설치 패키지들
sudo apt-get install qtquickcontrols2-5-dev libqt5serialport5-dev -y
sudo apt-get install ccache -y
sudo apt-get install qml-module-qtquick-controls2 -y
sudo apt-get install qml-module-qtmultimedia qml-module-qt-labs-platform -y
sudo apt-get install qml-module-qtquick-shapes -y # for Patrol page?



# 기존 패키지들에 대한 업데이트 
sudo apt-get update

sudo apt install libqt5websockets5-dev -y
sudo apt-get install qtmultimedia5-dev -y
sudo apt-get install libquazip5-dev -y
sudo apt-get -y install sshpass -y
sudo apt install qtdeclarative5-dev -y # vtk 빌드를 위한 QT5Qml, QT5Quick 설치
sudo apt install libvtk9-qt-dev -y
sudo apt install libpcl-dev -y
sudo apt install libeigen3-dev -y
sudo apt install libopencv-dev -y
sudo apt install libopencv-contrib-dev -y
sudo apt install libboost-all-dev -y

sudo apt install nmap-common -y #0725



echo "모든 작업이 완료되었습니다."

