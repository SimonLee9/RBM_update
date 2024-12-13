#!/bin/bash

sudo apt update

sudo apt install -y qtcreator qtbase5-dev qt5-qmake cmake libtbb-dev libboost-all-dev libopencv-dev libopencv-contrib-dev libeigen3-dev cmake-gui git htop build-essential rapidjson-dev libboost-system-dev libboost-thread-dev libssl-dev nmap qtmultimedia5-dev  libqt5multimedia5-plugins

sudo apt-get install gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly

sudo apt install libvtk9-qt-dev -y

sudo apt install libpcl-dev


# rtsp 스트리밍을 위해 추가됨 

sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-ugly gstreamer1.0-rtsp



echo "setup_slamnav2_apt의 모든 작업이 완료되었습니다."

