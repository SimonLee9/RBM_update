#!/bin/bash
# setup_all.sh
# 이 스크립트는 새로 포맷된 PC에서 실행되어
# 기본 시스템 업데이트, 필수 패키지 설치, 환경설정, 무선 드라이버 및 SLAMNAV2 관련 의존성들을 순차적으로 설치합니다.

# 스크립트를 root 권한으로 실행했는지 확인
if [ "$(id -u)" -ne 0 ]; then
    echo "이 스크립트는 root 권한으로 실행되어야 합니다. sudo를 사용하세요."
    exit 1
fi

# 오류 발생 시 메시지 출력 후 종료하는 함수
error_exit() {
    echo "오류: $1" 1>&2
    exit 1
}

##########################
# 1. 시스템 업데이트 및 필수 패키지 설치
##########################
echo "시스템 업데이트 및 필수 패키지 설치를 시작합니다..."
apt update || error_exit "패키지 목록 업데이트에 실패했습니다."
apt upgrade -y || error_exit "패키지 업그레이드에 실패했습니다."

# 필요한 패키지 목록 (여러 스크립트에서 중복되는 부분을 통합)
PACKAGES="gedit terminator net-tools dkms build-essential make qt5-default qtcreator qtdeclarative5-dev qttools5-dev libqt5x11extras5-dev libtbb-dev libboost-all-dev libopencv-dev libopencv-contrib-dev libeigen3-dev liblcm-dev cmake-gui git htop libqt5websockets5-dev qtmultimedia5-dev libquazip5-dev sshpass libvtk9-qt-dev libpcl-dev nmap-common qtbase5-dev qt5-qmake cmake rapidjson-dev libboost-system-dev libboost-thread-dev libssl-dev libqt5multimedia5-plugins gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-rtsp"

apt install -y $PACKAGES || error_exit "필수 패키지 설치에 실패했습니다."
echo "필수 패키지 설치가 완료되었습니다."

##########################
# 2. 시스템 환경 설정
##########################
echo "시스템 환경 설정을 진행합니다..."

# /etc/profile에 LD_LIBRARY_PATH 추가 (시스템 전역 적용)
echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib" >> /etc/profile
echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release" >> /etc/profile
echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rainbow/slamnav2" >> /etc/profile
source /etc/profile

ldconfig || error_exit "라이브러리 캐시 업데이트에 실패했습니다."

# GRUB 설정 수정 (USB 전원 관리 해제 및 intel_pstate 비활성화)
sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ usbcore.autosuspend=-1 intel_pstate=disable"/' /etc/default/grub || error_exit "GRUB 설정 수정에 실패했습니다."
update-grub || error_exit "GRUB 업데이트에 실패했습니다."

# 자동 업데이트 비활성화
cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades || error_exit "신규 Ubuntu 버전 알림 비활성화에 실패했습니다."

echo "시스템 환경 설정이 완료되었습니다."

##########################
# 3. Next 1200ac 무선 드라이버 설치 (rtl8812au)
##########################
echo "Next 1200ac 무선 드라이버 설치를 진행합니다..."
git clone https://github.com/gnab/rtl8812au.git || error_exit "rtl8812au 리포지토리 클론에 실패했습니다."
cp -r rtl8812au /usr/src/rtl8812au-4.2.2 || error_exit "rtl8812au 소스 복사에 실패했습니다."
dkms add -m rtl8812au -v 4.2.2 || error_exit "DKMS 추가에 실패했습니다."
dkms build -m rtl8812au -v 4.2.2 || error_exit "DKMS 빌드에 실패했습니다."
dkms install -m rtl8812au -v 4.2.2 || error_exit "DKMS 설치에 실패했습니다."
modprobe 8812au || error_exit "rtl8812au 모듈 로드에 실패했습니다."
echo "Next 1200ac 무선 드라이버 설치가 완료되었습니다."

##########################
# 4. SLAMNAV2 관련 의존성 및 SDK 설치 (소스 빌드)
##########################
echo "SLAMNAV2 관련 의존성 설치를 시작합니다..."
NUM_CORES=$(nproc)

# 4.1 CMake 3.27.7 설치
echo "CMake 3.27.7 설치 중..."
cd $HOME || error_exit "홈 디렉토리로 이동 실패."
CMAKE_VERSION=3.27.7
if [ ! -d "cmake-$CMAKE_VERSION" ]; then
    wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz || error_exit "CMake 다운로드 실패."
    tar -xvzf cmake-$CMAKE_VERSION.tar.gz || error_exit "CMake 압축 해제 실패."
fi
cd cmake-$CMAKE_VERSION || error_exit "CMake 디렉토리 이동 실패."
./bootstrap --qt-gui || error_exit "CMake 부트스트랩 실패."
make -j$NUM_CORES || error_exit "CMake 빌드 실패."
make install || error_exit "CMake 설치 실패."
cmake --version
echo "CMake 설치 완료."

# 4.2 Sophus 설치
echo "Sophus 설치 중..."
cd $HOME || error_exit "홈 디렉토리로 이동 실패."
if [ ! -d "Sophus" ]; then
    git clone https://github.com/strasdat/Sophus.git || error_exit "Sophus 클론 실패."
fi
cd Sophus || error_exit "Sophus 디렉토리 이동 실패."
mkdir -p build && cd build || error_exit "Sophus 빌드 디렉토리 생성 실패."
cmake .. -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DSOPHUS_USE_BASIC_LOGGING=ON || error_exit "Sophus CMake 구성 실패."
make -j$NUM_CORES || error_exit "Sophus 빌드 실패."
make install || error_exit "Sophus 설치 실패."
echo "Sophus 설치 완료."

# 4.3 GTSAM 설치 (버전 4.2.0)
echo "GTSAM 설치 중..."
cd $HOME || error_exit "홈 디렉토리로 이동 실패."
if [ ! -d "gtsam" ]; then
    git clone https://github.com/borglab/gtsam.git || error_exit "GTSAM 클론 실패."
fi
cd gtsam || error_exit "GTSAM 디렉토리 이동 실패."
git checkout 4.2.0 || error_exit "GTSAM 버전 체크아웃 실패."
mkdir -p build && cd build || error_exit "GTSAM 빌드 디렉토리 생성 실패."
cmake .. -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF || error_exit "GTSAM CMake 구성 실패."
make -j$NUM_CORES || error_exit "GTSAM 빌드 실패."
make install || error_exit "GTSAM 설치 실패."
echo "GTSAM 설치 완료."

# 4.4 OMPL 설치 (버전 1.6.0)
echo "OMPL 설치 중..."
cd $HOME || error_exit "홈 디렉토리로 이동 실패."
if [ ! -d "ompl" ]; then
    git clone https://github.com/ompl/ompl.git || error_exit "OMPL 클론 실패."
fi
cd ompl || error_exit "OMPL 디렉토리 이동 실패."
git checkout 1.6.0 || error_exit "OMPL 버전 체크아웃 실패."
mkdir -p build && cd build || error_exit "OMPL 빌드 디렉토리 생성 실패."
cmake .. || error_exit "OMPL CMake 구성 실패."
make -j$NUM_CORES || error_exit "OMPL 빌드 실패."
make install || error_exit "OMPL 설치 실패."
echo "OMPL 설치 완료."

# 4.5 socket.io-client-cpp 설치
echo "socket.io-client-cpp 설치 중..."
cd $HOME || error_exit "홈 디렉토리로 이동 실패."
if [ ! -d "socket.io-client-cpp" ]; then
    git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git || error_exit "socket.io-client-cpp 클론 실패."
fi
cd socket.io-client-cpp || error_exit "socket.io-client-cpp 디렉토리 이동 실패."
mkdir -p build && cd build || error_exit "socket.io-client-cpp 빌드 디렉토리 생성 실패."
cmake .. -DBUILD_SHARED_LIBS=ON -DLOGGING=OFF || error_exit "socket.io-client-cpp CMake 구성 실패."
make -j$NUM_CORES || error_exit "socket.io-client-cpp 빌드 실패."
make install || error_exit "socket.io-client-cpp 설치 실패."
echo "socket.io-client-cpp 설치 완료."

# 4.6 OctoMap 설치 (버전 1.10.0)
echo "OctoMap 설치 중..."
cd $HOME || error_exit "홈 디렉토리로 이동 실패."
if [ ! -d "octomap" ]; then
    git clone https://github.com/OctoMap/octomap.git || error_exit "OctoMap 클론 실패."
fi
cd octomap || error_exit "OctoMap 디렉토리 이동 실패."
git checkout v1.10.0 || error_exit "OctoMap 버전 체크아웃 실패."
mkdir -p build && cd build || error_exit "OctoMap 빌드 디렉토리 생성 실패."
cmake .. -DBUILD_DYNAMICETD3D=OFF -DBUILD_OCTOVIS_SUBPROJECT=OFF -DBUILD_TESTING=OFF || error_exit "OctoMap CMake 구성 실패."
make -j$NUM_CORES || error_exit "OctoMap 빌드 실패."
make install || error_exit "OctoMap 설치 실패."
echo "OctoMap 설치 완료."

# 4.7 OrbbecSDK 설치 (버전 v1.10.11)
echo "OrbbecSDK 설치 중..."
cd $HOME || error_exit "홈 디렉토리로 이동 실패."
if [ ! -d "OrbbecSDK" ]; then
    git clone https://github.com/orbbec/OrbbecSDK.git || error_exit "OrbbecSDK 클론 실패."
fi
cd OrbbecSDK || error_exit "OrbbecSDK 디렉토리 이동 실패."
git checkout v1.10.11 || error_exit "OrbbecSDK 버전 체크아웃 실패."
cd misc/scripts || error_exit "OrbbecSDK 스크립트 디렉토리 이동 실패."
sh install_udev_rules.sh || error_exit "OrbbecSDK udev 규칙 설치 실패."
echo "OrbbecSDK 설치 완료."

# 4.8 RPlidar SDK 설치 (release/v1.12.0)
echo "RPlidar SDK 설치 중..."
cd $HOME || error_exit "홈 디렉토리로 이동 실패."
if [ ! -d "rplidar_sdk" ]; then
    git clone https://github.com/Slamtec/rplidar_sdk.git || error_exit "RPlidar SDK 클론 실패."
fi
cd rplidar_sdk || error_exit "RPlidar SDK 디렉토리 이동 실패."
git checkout release/v1.12.0 || error_exit "RPlidar SDK 버전 체크아웃 실패."
make -j$NUM_CORES || error_exit "RPlidar SDK 빌드 실패."
# ~/.bashrc에 LD_LIBRARY_PATH 추가 (중복되지 않으면)
if ! grep -q "rplidar_sdk" ~/.bashrc; then
    echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release" >> ~/.bashrc
fi
source ~/.bashrc
ldconfig
echo "RPlidar SDK 설치 완료."

echo "모든 설치 작업이 성공적으로 완료되었습니다."

