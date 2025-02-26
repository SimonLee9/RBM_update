#!/bin/bash
# setup_all.sh
# 새로 포맷된 PC에서 실행되는 통합 설치 스크립트입니다.
# 각 설치 단계에서 실패하면 오류를 기록하고, 스크립트 전체는 중단하지 않습니다.
# 마지막에 실패한 항목들을 요약하여 출력합니다.

# 전역 오류 배열
FAILURES=()

# 오류를 기록하는 함수
log_failure() {
    local msg="$1"
    FAILURES+=("$msg")
    echo "오류 발생: $msg"
}

# 스크립트를 root 권한으로 실행했는지 확인 (실패해도 계속 진행)
if [ "$(id -u)" -ne 0 ]; then
    log_failure "이 스크립트는 root 권한으로 실행되어야 합니다. sudo를 사용하세요."
fi

##########################
# 1. 시스템 업데이트 및 필수 패키지 설치
##########################
echo "1. 시스템 업데이트 및 필수 패키지 설치를 시작합니다..."
apt update || log_failure "패키지 목록 업데이트 실패"
apt upgrade -y || log_failure "패키지 업그레이드 실패"

# 중복 설치되는 패키지들을 하나의 목록으로 통합
PACKAGES="gedit terminator net-tools dkms build-essential make qt5-default qtcreator qtdeclarative5-dev qttools5-dev libqt5x11extras5-dev libtbb-dev libboost-all-dev libopencv-dev libopencv-contrib-dev libeigen3-dev liblcm-dev cmake-gui git htop libqt5websockets5-dev qtmultimedia5-dev libquazip5-dev sshpass libvtk9-qt-dev libpcl-dev nmap-common qtbase5-dev qt5-qmake cmake rapidjson-dev libboost-system-dev libboost-thread-dev libssl-dev libqt5multimedia5-plugins gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-rtsp"

apt install -y $PACKAGES || log_failure "필수 패키지 설치에 실패했습니다 (패키지: qt5-default 등 일부 패키지 후보 없음 포함)"

echo "필수 패키지 설치 단계 완료."

##########################
# 2. 시스템 환경 설정
##########################
echo "2. 시스템 환경 설정을 진행합니다..."

# /etc/profile에 환경 변수 추가
echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib" >> /etc/profile || log_failure "LD_LIBRARY_PATH (/usr/local/lib) 추가 실패"
echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release" >> /etc/profile || log_failure "LD_LIBRARY_PATH (rplidar_sdk) 추가 실패"
source /etc/profile || log_failure "프로필 적용 실패"
ldconfig || log_failure "라이브러리 캐시 업데이트 실패"

# GRUB 설정 수정 (USB 전원 관리 해제 및 intel_pstate 비활성화)
sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ usbcore.autosuspend=-1 intel_pstate=disable"/' /etc/default/grub || log_failure "GRUB 설정 수정 실패"
update-grub || log_failure "GRUB 업데이트 실패"

# 자동 업데이트 비활성화
cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF
if [ $? -ne 0 ]; then log_failure "자동 업데이트 비활성화 설정 실패"; fi

sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades || log_failure "신규 Ubuntu 버전 알림 비활성화 실패"

echo "시스템 환경 설정 단계 완료."

##########################
# 3. Next 1200ac 무선 드라이버 설치 (rtl8812au)
##########################
echo "3. Next 1200ac 무선 드라이버 설치를 진행합니다..."
git clone https://github.com/gnab/rtl8812au.git || log_failure "rtl8812au 리포지토리 클론 실패"
cp -r rtl8812au /usr/src/rtl8812au-4.2.2 || log_failure "rtl8812au 소스 복사 실패"
dkms add -m rtl8812au -v 4.2.2 || log_failure "DKMS 추가 실패 (rtl8812au)"
dkms build -m rtl8812au -v 4.2.2 || log_failure "DKMS 빌드 실패 (rtl8812au)"
dkms install -m rtl8812au -v 4.2.2 || log_failure "DKMS 설치 실패 (rtl8812au)"
modprobe 8812au || log_failure "rtl8812au 모듈 로드 실패"
echo "무선 드라이버 설치 단계 완료."

##########################
# 4. SLAMNAV2 관련 의존성 및 SDK 설치 (소스 빌드)
##########################
echo "4. SLAMNAV2 관련 의존성 및 SDK 설치를 시작합니다..."
NUM_CORES=$(nproc)

# 4.1 CMake 3.27.7 설치
echo "4.1 CMake 3.27.7 설치 중..."
cd $HOME || log_failure "홈 디렉토리 이동 실패 (CMake)"
CMAKE_VERSION=3.27.7
if [ ! -d "cmake-$CMAKE_VERSION" ]; then
    wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz || log_failure "CMake 다운로드 실패"
    tar -xvzf cmake-$CMAKE_VERSION.tar.gz || log_failure "CMake 압축 해제 실패"
fi
cd cmake-$CMAKE_VERSION || log_failure "CMake 디렉토리 이동 실패"
./bootstrap --qt-gui || log_failure "CMake 부트스트랩 실패"
make -j$NUM_CORES || log_failure "CMake 빌드 실패"
make install || log_failure "CMake 설치 실패"
cmake --version || log_failure "CMake 버전 확인 실패"
echo "CMake 설치 완료."

# 4.2 Sophus 설치
echo "4.2 Sophus 설치 중..."
cd $HOME || log_failure "홈 디렉토리 이동 실패 (Sophus)"
if [ ! -d "Sophus" ]; then
    git clone https://github.com/strasdat/Sophus.git || log_failure "Sophus 클론 실패"
fi
cd Sophus || log_failure "Sophus 디렉토리 이동 실패"
mkdir -p build && cd build || log_failure "Sophus 빌드 디렉토리 생성 실패"
cmake .. -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DSOPHUS_USE_BASIC_LOGGING=ON || log_failure "Sophus CMake 구성 실패"
make -j$NUM_CORES || log_failure "Sophus 빌드 실패"
make install || log_failure "Sophus 설치 실패"
echo "Sophus 설치 완료."

# 4.3 GTSAM 설치 (버전 4.2.0)
echo "4.3 GTSAM 설치 중..."
cd $HOME || log_failure "홈 디렉토리 이동 실패 (GTSAM)"
if [ ! -d "gtsam" ]; then
    git clone https://github.com/borglab/gtsam.git || log_failure "GTSAM 클론 실패"
fi
cd gtsam || log_failure "GTSAM 디렉토리 이동 실패"
git checkout 4.2.0 || log_failure "GTSAM 버전 4.2.0 체크아웃 실패"
mkdir -p build && cd build || log_failure "GTSAM 빌드 디렉토리 생성 실패"
cmake .. -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF || log_failure "GTSAM CMake 구성 실패"
make -j$NUM_CORES || log_failure "GTSAM 빌드 실패"
make install || log_failure "GTSAM 설치 실패"
echo "GTSAM 설치 완료."

# 4.4 OMPL 설치 (버전 1.6.0)
echo "4.4 OMPL 설치 중..."
cd $HOME || log_failure "홈 디렉토리 이동 실패 (OMPL)"
if [ ! -d "ompl" ]; then
    git clone https://github.com/ompl/ompl.git || log_failure "OMPL 클론 실패"
fi
cd ompl || log_failure "OMPL 디렉토리 이동 실패"
git checkout 1.6.0 || log_failure "OMPL 버전 1.6.0 체크아웃 실패"
mkdir -p build && cd build || log_failure "OMPL 빌드 디렉토리 생성 실패"
cmake .. || log_failure "OMPL CMake 구성 실패"
make -j$NUM_CORES || log_failure "OMPL 빌드 실패"
make install || log_failure "OMPL 설치 실패"
echo "OMPL 설치 완료."

# 4.5 socket.io-client-cpp 설치
echo "4.5 socket.io-client-cpp 설치 중..."
cd $HOME || log_failure "홈 디렉토리 이동 실패 (socket.io-client-cpp)"
if [ ! -d "socket.io-client-cpp" ]; then
    git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git || log_failure "socket.io-client-cpp 클론 실패"
fi
cd socket.io-client-cpp || log_failure "socket.io-client-cpp 디렉토리 이동 실패"
mkdir -p build && cd build || log_failure "socket.io-client-cpp 빌드 디렉토리 생성 실패"
cmake .. -DBUILD_SHARED_LIBS=ON -DLOGGING=OFF || log_failure "socket.io-client-cpp CMake 구성 실패"
make -j$NUM_CORES || log_failure "socket.io-client-cpp 빌드 실패"
make install || log_failure "socket.io-client-cpp 설치 실패"
echo "socket.io-client-cpp 설치 완료."

# 4.6 OctoMap 설치 (버전 1.10.0)
echo "4.6 OctoMap 설치 중..."
cd $HOME || log_failure "홈 디렉토리 이동 실패 (OctoMap)"
if [ ! -d "octomap" ]; then
    git clone https://github.com/OctoMap/octomap.git || log_failure "OctoMap 클론 실패"
fi
cd octomap || log_failure "OctoMap 디렉토리 이동 실패"
git checkout v1.10.0 || log_failure "OctoMap 버전 1.10.0 체크아웃 실패"
mkdir -p build && cd build || log_failure "OctoMap 빌드 디렉토리 생성 실패"
cmake .. -DBUILD_DYNAMICETD3D=OFF -DBUILD_OCTOVIS_SUBPROJECT=OFF -DBUILD_TESTING=OFF || log_failure "OctoMap CMake 구성 실패"
make -j$NUM_CORES || log_failure "OctoMap 빌드 실패"
make install || log_failure "OctoMap 설치 실패"
echo "OctoMap 설치 완료."

# 4.7 OrbbecSDK 설치 (버전 v1.10.11)
echo "4.7 OrbbecSDK 설치 중..."
cd $HOME || log_failure "홈 디렉토리 이동 실패 (OrbbecSDK)"
if [ ! -d "OrbbecSDK" ]; then
    git clone https://github.com/orbbec/OrbbecSDK.git || log_failure "OrbbecSDK 클론 실패"
fi
cd OrbbecSDK || log_failure "OrbbecSDK 디렉토리 이동 실패"
git checkout v1.10.11 || log_failure "OrbbecSDK 버전 v1.10.11 체크아웃 실패"
cd misc/scripts || log_failure "OrbbecSDK 스크립트 디렉토리 이동 실패"
sh install_udev_rules.sh || log_failure "OrbbecSDK udev 규칙 설치 실패"
echo "OrbbecSDK 설치 완료."

# 4.8 RPlidar SDK 설치 (release/v1.12.0)
echo "4.8 RPlidar SDK 설치 중..."
cd $HOME || log_failure "홈 디렉토리 이동 실패 (RPlidar SDK)"
if [ ! -d "rplidar_sdk" ]; then
    git clone https://github.com/Slamtec/rplidar_sdk.git || log_failure "RPlidar SDK 클론 실패"
fi
cd rplidar_sdk || log_failure "RPlidar SDK 디렉토리 이동 실패"
git checkout release/v1.12.0 || log_failure "RPlidar SDK 버전 release/v1.12.0 체크아웃 실패"
make -j$NUM_CORES || log_failure "RPlidar SDK 빌드 실패"
# ~/.bashrc에 LD_LIBRARY_PATH 추가 (중복되지 않으면)
grep -q "rplidar_sdk" ~/.bashrc || echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release" >> ~/.bashrc
source ~/.bashrc || log_failure ".bashrc 적용 실패"
ldconfig || log_failure "ldconfig 실행 실패"
echo "RPlidar SDK 설치 완료."

echo "SLAMNAV2 관련 의존성 및 SDK 설치 단계 완료."

##########################
# 5. 최종 오류 요약
##########################
echo "-------------------------------------"
if [ ${#FAILURES[@]} -ne 0 ]; then
    echo "설치 과정 중 다음 항목들이 실패했습니다:"
    for err in "${FAILURES[@]}"; do
         echo " - $err"
    done
    echo "-------------------------------------"
    echo "일부 설치 항목에 실패하였습니다. 설치 로그를 확인하세요."
else
    echo "모든 설치 작업이 성공적으로 완료되었습니다."
fi

