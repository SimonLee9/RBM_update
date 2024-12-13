#!/bin/bash

# 병렬 make를 위한 코어 수
NUM_CORES=$(nproc)

# 시스템 업데이트 및 업그레이드 (선택 사항)
# sudo apt update && sudo apt upgrade -y

# 오류 처리를 위한 함수
error_exit() {
    echo "$1" 1>&2
    exit 1
}



# OMPL 설치
echo "OMPL을 설치 중입니다..."
cd ~ || error_exit "홈 디렉토리로 이동하지 못했습니다."
if [ ! -d "ompl" ]; then
    git clone https://github.com/ompl/ompl.git || error_exit "OMPL 리포지토리를 클론하지 못했습니다."
fi
cd ompl || error_exit "OMPL 디렉토리에 들어가지 못했습니다."
git checkout 1.6.0 || error_exit "OMPL 버전 1.6.0 체크아웃에 실패했습니다."
mkdir -p build && cd build
cmake .. || error_exit "OMPL의 CMake 구성에 실패했습니다."
make -j$NUM_CORES || error_exit "OMPL 빌드에 실패했습니다."
sudo make install || error_exit "OMPL 설치에 실패했습니다."

# socket.io-client-cpp 설치
echo "socket.io-client-cpp를 설치 중입니다..."
cd ~ || error_exit "홈 디렉토리로 이동하지 못했습니다."
if [ ! -d "socket.io-client-cpp" ]; then
    git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git || error_exit "socket.io-client-cpp 리포지토리를 클론하지 못했습니다."
fi
cd socket.io-client-cpp || error_exit "socket.io-client-cpp 디렉토리에 들어가지 못했습니다."
mkdir -p build && cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DLOGGING=OFF || error_exit "socket.io-client-cpp의 CMake 구성에 실패했습니다."
make -j$NUM_CORES || error_exit "socket.io-client-cpp 빌드에 실패했습니다."
sudo make install || error_exit "socket.io-client-cpp 설치에 실패했습니다."

# OctoMap 설치
echo "OctoMap을 설치 중입니다..."
cd ~ || error_exit "홈 디렉토리로 이동하지 못했습니다."
if [ ! -d "octomap" ]; then
    git clone https://github.com/OctoMap/octomap.git || error_exit "OctoMap 리포지토리를 클론하지 못했습니다."
fi
cd octomap || error_exit "OctoMap 디렉토리에 들어가지 못했습니다."
git checkout v1.10.0 || error_exit "OctoMap 버전 1.10.0 체크아웃에 실패했습니다."
mkdir -p build && cd build
cmake .. -DBUILD_DYNAMICETD3D=OFF -DBUILD_OCTOVIS_SUBPROJECT=OFF -DBUILD_TESTING=OFF || error_exit "OctoMap의 CMake 구성에 실패했습니다."
make -j$NUM_CORES || error_exit "OctoMap 빌드에 실패했습니다."
sudo make install || error_exit "OctoMap 설치에 실패했습니다."

# OrbbecSDK 설치
echo "OrbbecSDK를 설치 중입니다..."
cd ~ || error_exit "홈 디렉토리로 이동하지 못했습니다."
if [ ! -d "OrbbecSDK" ]; then
    git clone https://github.com/orbbec/OrbbecSDK.git || error_exit "OrbbecSDK 리포지토리를 클론하지 못했습니다."
fi
cd OrbbecSDK || error_exit "OrbbecSDK 디렉토리에 들어가지 못했습니다."
git checkout v1.10.11 || error_exit "OrbbecSDK 버전 v1.10.11 체크아웃에 실패했습니다."
cd misc/scripts || error_exit "스크립트 디렉토리에 들어가지 못했습니다."
sudo sh install_udev_rules.sh || error_exit "OrbbecSDK의 udev 규칙 설치에 실패했습니다."

# RPlidar SDK 설치
echo "RPlidar SDK를 설치 중입니다..."
cd ~ || error_exit "홈 디렉토리로 이동하지 못했습니다."
if [ ! -d "rplidar_sdk" ]; then
    git clone https://github.com/Slamtec/rplidar_sdk.git || error_exit "RPlidar SDK 리포지토리를 클론하지 못했습니다."
fi
cd rplidar_sdk || error_exit "RPlidar SDK 디렉토리에 들어가지 못했습니다."
git checkout release/v1.12.0 || error_exit "RPlidar SDK 버전 v1.12.0 체크아웃에 실패했습니다."
make -j$NUM_CORES || error_exit "RPlidar SDK 빌드에 실패했습니다."

# RPlidar SDK를 LD_LIBRARY_PATH에 추가
echo "LD_LIBRARY_PATH를 업데이트 중입니다..."
if ! grep -q "rplidar_sdk" ~/.bashrc; then
    echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:$HOME/rplidar_sdk/output/Linux/Release" >> ~/.bashrc
fi
source ~/.bashrc
sudo ldconfig

echo "모든 설치가 성공적으로 완료되었습니다."

