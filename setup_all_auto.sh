#!/bin/bash
# setup_all_auto.sh
# 새로 포맷된 PC에서 실행되는 통합 설치 스크립트 (자동 재설치)
# 이미 설치된 항목이 있으면 사용자에게 묻지 않고 삭제 후 재설치합니다.
# 주요 명령은 최대 3회 재시도합니다.

##########################
# 재시도 함수: 주어진 명령을 최대 3회 재시도 (각 시도 사이 2초 대기)
##########################
retry_cmd() {
    local retries=3
    local count=0
    until "$@"; do
        count=$((count+1))
        if [ $count -lt $retries ]; then
            echo "명령 재시도 ($count번째 시도): $*"
            sleep 2
        else
            echo "최종 시도 실패: $*"
            return 1
        fi
    done
    return 0
}

##########################
# 실패 메시지를 기록하는 함수
##########################
FAILURES=()
log_failure() {
    local msg="$1"
    FAILURES+=("$msg")
    echo "오류 발생: $msg"
}

##########################
# apt 패키지 설치 함수 (이미 설치되어 있으면 제거 후 재설치)
##########################
install_package() {
    local pkg="$1"
    
    if dpkg -l | grep -qw "$pkg"; then
        echo "패키지 '$pkg'가 이미 설치되어 있으므로 제거 후 재설치합니다."
        retry_cmd apt-get remove --purge -y "$pkg" || log_failure "패키지 '$pkg' 제거 실패"
    fi
    retry_cmd apt-get install -y "$pkg" || log_failure "패키지 '$pkg' 설치 실패"
}

install_packages() {
    local pkgs=("$@")
    for pkg in "${pkgs[@]}"; do
        install_package "$pkg"
    done
}

##########################
# Git 리포지토리 클론 함수 (디렉토리 존재 시 자동 삭제 후 재클론)
##########################
clone_repo() {
    local repo_url="$1"
    local target_dir="$2"
    if [ -d "$target_dir" ]; then
        echo "디렉토리 '$target_dir'가 이미 존재하므로 삭제 후 재클론합니다."
        rm -rf "$target_dir" || log_failure "디렉토리 '$target_dir' 제거 실패"
    fi
    retry_cmd git clone "$repo_url" "$target_dir" || log_failure "리포지토리 '$repo_url' 클론 실패"
}

##########################
# DKMS 모듈 설치 함수 (모듈이 이미 존재하면 자동 제거 후 재설치)
##########################
setup_dkms_module() {
    local module_dir="$1"
    local module_name="$2"
    local module_version="$3"
    if [ -d "/usr/src/${module_name}-${module_version}" ]; then
        echo "DKMS 모듈 '/usr/src/${module_name}-${module_version}'가 이미 존재하므로 제거합니다."
        retry_cmd dkms remove -m "$module_name" -v "$module_version" --all || log_failure "DKMS 모듈 제거 실패: $module_name"
    fi
    retry_cmd cp -r "$module_dir" "/usr/src/${module_name}-${module_version}" || log_failure "$module_name 소스 복사 실패"
    retry_cmd dkms add -m "$module_name" -v "$module_version" || log_failure "DKMS 추가 실패 ($module_name)"
    retry_cmd dkms build -m "$module_name" -v "$module_version" || log_failure "DKMS 빌드 실패 ($module_name)"
    retry_cmd dkms install -m "$module_name" -v "$module_version" || log_failure "DKMS 설치 실패 ($module_name)"
    retry_cmd modprobe 8812au || log_failure "$module_name 모듈 로드 실패"
}

##########################
# 메인 스크립트 시작
##########################
echo "자동 재설치 스크립트를 시작합니다."

# root 권한 확인
if [ "$(id -u)" -ne 0 ]; then
    echo "이 스크립트는 root 권한으로 실행되어야 합니다. sudo로 실행하세요."
    log_failure "root 권한이 아님"
fi

##########################
# 1. 시스템 업데이트 및 필수 패키지 설치
##########################
echo "1. 시스템 업데이트 및 필수 패키지 설치를 시작합니다..."
retry_cmd apt-get update || log_failure "패키지 목록 업데이트 실패"
retry_cmd apt-get upgrade -y || log_failure "패키지 업그레이드 실패"

packages=(
  "build-essential"
  "make"
  # "qt5-default" => 사용 중지
  "qtcreator"
  "qtdeclarative5-dev"
  "qttools5-dev"
  "libqt5x11extras5-dev"
  "libtbb-dev"
  "libboost-all-dev"
  "libopencv-dev"
  "libopencv-contrib-dev"
  "libeigen3-dev"
  "liblcm-dev"
  "cmake-gui"
  "git"
  "htop"
  "libqt5websockets5-dev"
  "qtmultimedia5-dev"
  "libquazip5-dev"
  "sshpass"
  "libvtk9-qt-dev"
  "libpcl-dev"
  "nmap-common"
  "qtbase5-dev"
  "qt5-qmake"
  "cmake"
  "rapidjson-dev"
  "libboost-system-dev"
  "libboost-thread-dev"
  "libssl-dev"
  "libqt5multimedia5-plugins"
  "gstreamer1.0-plugins-base"
  "gstreamer1.0-plugins-good"
  "gstreamer1.0-plugins-bad"
  "gstreamer1.0-plugins-ugly"
  "libgstreamer1.0-dev"
  "libgstreamer-plugins-base1.0-dev"
  "gstreamer1.0-rtsp"
  "libqt5serialport5-dev"
  # 새로 추가
  "libqt5gamepad5-dev"
)
install_packages "${packages[@]}"
echo "필수 패키지 설치 단계 완료."

##########################
# 2. 시스템 환경 설정
##########################
echo "2. 시스템 환경 설정을 진행합니다..."
{
  echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib" >> /etc/profile
  echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release" >> /etc/profile
  source /etc/profile
  retry_cmd ldconfig || log_failure "라이브러리 캐시 업데이트 실패"
} || log_failure "LD_LIBRARY_PATH 추가 실패"

retry_cmd sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ usbcore.autosuspend=-1 intel_pstate=disable"/' /etc/default/grub || log_failure "GRUB 설정 수정 실패"
retry_cmd update-grub || log_failure "GRUB 업데이트 실패"

cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF
if [ $? -ne 0 ]; then log_failure "자동 업데이트 비활성화 설정 실패"; fi

retry_cmd sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades || log_failure "신규 Ubuntu 버전 알림 비활성화 실패"
echo "시스템 환경 설정 단계 완료."

##########################
# 3. Next 1200ac 무선 드라이버 설치 (rtl8812au)
##########################
echo "3. Next 1200ac 무선 드라이버 설치를 진행합니다..."
clone_repo "https://github.com/gnab/rtl8812au.git" "rtl8812au"
setup_dkms_module "rtl8812au" "rtl8812au" "4.2.2"
echo "무선 드라이버 설치 단계 완료."

##########################
# 4. SLAMNAV2 관련 의존성 및 SDK 설치 (소스 빌드)
##########################
echo "4. SLAMNAV2 관련 의존성 및 SDK 설치를 시작합니다..."
NUM_CORES=$(nproc)

# 4.1 CMake 3.27.7 설치
echo "4.1 CMake 3.27.7 설치 중..."
cd "$HOME" || log_failure "홈 디렉토리 이동 실패 (CMake)"
CMAKE_VERSION=3.27.7
CMAKE_DIR="$HOME/cmake-$CMAKE_VERSION"
if [ -d "$CMAKE_DIR" ]; then
    echo "CMake 디렉토리 '$CMAKE_DIR'가 이미 존재하므로 삭제합니다."
    rm -rf "$CMAKE_DIR" || log_failure "CMake 디렉토리 제거 실패"
fi
retry_cmd wget "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz" -O "$HOME/cmake-$CMAKE_VERSION.tar.gz" || log_failure "CMake 다운로드 실패"
retry_cmd tar -xvzf "$HOME/cmake-$CMAKE_VERSION.tar.gz" -C "$HOME" || log_failure "CMake 압축 해제 실패"
cd "$CMAKE_DIR" || log_failure "CMake 디렉토리 이동 실패"
retry_cmd ./bootstrap --qt-gui || log_failure "CMake 부트스트랩 실패"
retry_cmd make -j"$NUM_CORES" || log_failure "CMake 빌드 실패"
retry_cmd make install || log_failure "CMake 설치 실패"
retry_cmd cmake --version || log_failure "CMake 버전 확인 실패"
echo "CMake 설치 완료."

# 4.2 Sophus 설치
echo "4.2 Sophus 설치 중..."
cd "$HOME" || log_failure "홈 디렉토리 이동 실패 (Sophus)"
if [ -d "$HOME/Sophus" ]; then
    echo "Sophus 디렉토리 '$HOME/Sophus'가 이미 존재하므로 삭제합니다."
    rm -rf "$HOME/Sophus" || log_failure "Sophus 디렉토리 제거 실패"
fi
retry_cmd git clone https://github.com/strasdat/Sophus.git "$HOME/Sophus" || log_failure "Sophus 클론 실패"
cd "$HOME/Sophus" || log_failure "Sophus 디렉토리 이동 실패"
mkdir -p build && cd build || log_failure "Sophus 빌드 디렉토리 생성 실패"
retry_cmd cmake .. -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DSOPHUS_USE_BASIC_LOGGING=ON || log_failure "Sophus CMake 구성 실패"
retry_cmd make -j"$NUM_CORES" || log_failure "Sophus 빌드 실패"
retry_cmd make install || log_failure "Sophus 설치 실패"
echo "Sophus 설치 완료."

# 4.3 GTSAM 설치 (버전 4.2.0)
echo "4.3 GTSAM 설치 중..."
cd "$HOME" || log_failure "홈 디렉토리 이동 실패 (GTSAM)"
if [ -d "$HOME/gtsam" ]; then
    echo "GTSAM 디렉토리 '$HOME/gtsam'가 이미 존재하므로 삭제합니다."
    rm -rf "$HOME/gtsam" || log_failure "GTSAM 디렉토리 제거 실패"
fi
retry_cmd git clone https://github.com/borglab/gtsam.git "$HOME/gtsam" || log_failure "GTSAM 클론 실패"
cd "$HOME/gtsam" || log_failure "GTSAM 디렉토리 이동 실패"
retry_cmd git checkout 4.2.0 || log_failure "GTSAM 버전 4.2.0 체크아웃 실패"
mkdir -p build && cd build || log_failure "GTSAM 빌드 디렉토리 생성 실패"
retry_cmd cmake .. -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF || log_failure "GTSAM CMake 구성 실패"
retry_cmd make -j"$NUM_CORES" || log_failure "GTSAM 빌드 실패"
retry_cmd make install || log_failure "GTSAM 설치 실패"
echo "GTSAM 설치 완료."

# 4.4 OMPL 설치 (버전 1.6.0)
echo "4.4 OMPL 설치 중..."
cd "$HOME" || log_failure "홈 디렉토리 이동 실패 (OMPL)"
if [ -d "$HOME/ompl" ]; then
    echo "OMPL 디렉토리 '$HOME/ompl'가 이미 존재하므로 삭제합니다."
    rm -rf "$HOME/ompl" || log_failure "OMPL 디렉토리 제거 실패"
fi
retry_cmd git clone https://github.com/ompl/ompl.git "$HOME/ompl" || log_failure "OMPL 클론 실패"
cd "$HOME/ompl" || log_failure "OMPL 디렉토리 이동 실패"
retry_cmd git checkout 1.6.0 || log_failure "OMPL 버전 1.6.0 체크아웃 실패"
mkdir -p build && cd build || log_failure "OMPL 빌드 디렉토리 생성 실패"
retry_cmd cmake .. || log_failure "OMPL CMake 구성 실패"
retry_cmd make -j"$NUM_CORES" || log_failure "OMPL 빌드 실패"
retry_cmd make install || log_failure "OMPL 설치 실패"
echo "OMPL 설치 완료."

# 4.5 socket.io-client-cpp 설치
echo "4.5 socket.io-client-cpp 설치 중..."
cd "$HOME" || log_failure "홈 디렉토리 이동 실패 (socket.io-client-cpp)"
if [ -d "$HOME/socket.io-client-cpp" ]; then
    echo "socket.io-client-cpp 디렉토리 '$HOME/socket.io-client-cpp'가 이미 존재하므로 삭제합니다."
    rm -rf "$HOME/socket.io-client-cpp" || log_failure "socket.io-client-cpp 디렉토리 제거 실패"
fi
retry_cmd git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git "$HOME/socket.io-client-cpp" || log_failure "socket.io-client-cpp 클론 실패"
cd "$HOME/socket.io-client-cpp" || log_failure "socket.io-client-cpp 디렉토리 이동 실패"
mkdir -p build && cd build || log_failure "socket.io-client-cpp 빌드 디렉토리 생성 실패"
retry_cmd cmake .. -DBUILD_SHARED_LIBS=ON -DLOGGING=OFF || log_failure "socket.io-client-cpp CMake 구성 실패"
retry_cmd make -j"$NUM_CORES" || log_failure "socket.io-client-cpp 빌드 실패"
retry_cmd make install || log_failure "socket.io-client-cpp 설치 실패"
echo "socket.io-client-cpp 설치 완료."

# 4.6 OctoMap 설치 (버전 1.10.0)
echo "4.6 OctoMap 설치 중..."
cd "$HOME" || log_failure "홈 디렉토리 이동 실패 (OctoMap)"
if [ -d "$HOME/octomap" ]; then
    echo "OctoMap 디렉토리 '$HOME/octomap'가 이미 존재하므로 삭제합니다."
    rm -rf "$HOME/octomap" || log_failure "OctoMap 디렉토리 제거 실패"
fi
retry_cmd git clone https://github.com/OctoMap/octomap.git "$HOME/octomap" || log_failure "OctoMap 클론 실패"
cd "$HOME/octomap" || log_failure "OctoMap 디렉토리 이동 실패"
retry_cmd git checkout v1.10.0 || log_failure "OctoMap 버전 1.10.0 체크아웃 실패"
mkdir -p build && cd build || log_failure "OctoMap 빌드 디렉토리 생성 실패"
retry_cmd cmake .. -DBUILD_DYNAMICETD3D=OFF -DBUILD_OCTOVIS_SUBPROJECT=OFF -DBUILD_TESTING=OFF || log_failure "OctoMap CMake 구성 실패"
retry_cmd make -j"$NUM_CORES" || log_failure "OctoMap 빌드 실패"
retry_cmd make install || log_failure "OctoMap 설치 실패"
echo "OctoMap 설치 완료."

# 4.7 OrbbecSDK 설치 (버전 v1.10.11)
echo "4.7 OrbbecSDK 설치 중..."
cd "$HOME" || log_failure "홈 디렉토리 이동 실패 (OrbbecSDK)"
if [ -d "$HOME/OrbbecSDK" ]; then
    echo "OrbbecSDK 디렉토리 '$HOME/OrbbecSDK'가 이미 존재하므로 삭제합니다."
    rm -rf "$HOME/OrbbecSDK" || log_failure "OrbbecSDK 디렉토리 제거 실패"
fi
retry_cmd git clone https://github.com/orbbec/OrbbecSDK.git "$HOME/OrbbecSDK" || log_failure "OrbbecSDK 클론 실패"
cd "$HOME/OrbbecSDK" || log_failure "OrbbecSDK 디렉토리 이동 실패"
retry_cmd git checkout v1.10.11 || log_failure "OrbbecSDK 버전 v1.10.11 체크아웃 실패"
cd misc/scripts || log_failure "OrbbecSDK 스크립트 디렉토리 이동 실패"
retry_cmd sh install_udev_rules.sh || log_failure "OrbbecSDK udev 규칙 설치 실패"
echo "OrbbecSDK 설치 완료."

# 4.8 RPlidar SDK 설치 (release/v1.12.0)
echo "4.8 RPlidar SDK 설치 중..."
cd "$HOME" || log_failure "홈 디렉토리 이동 실패 (RPlidar SDK)"
if [ -d "$HOME/rplidar_sdk" ]; then
    echo "RPlidar SDK 디렉토리 '$HOME/rplidar_sdk'가 이미 존재하므로 삭제합니다."
    rm -rf "$HOME/rplidar_sdk" || log_failure "RPlidar SDK 디렉토리 제거 실패"
fi
retry_cmd git clone https://github.com/Slamtec/rplidar_sdk.git "$HOME/rplidar_sdk" || log_failure "RPlidar SDK 클론 실패"
cd "$HOME/rplidar_sdk" || log_failure "RPlidar SDK 디렉토리 이동 실패"
# retry_cmd git checkout release/v1.12.0 || log_failure "RPlidar SDK 버전 release/v1.12.0 체크아웃 실패"
retry_cmd make -j"$NUM_CORES" || log_failure "RPlidar SDK 빌드 실패"
# ~/.bashrc에 LD_LIBRARY_PATH 항목 추가 (없으면)
grep -q "rplidar_sdk" "$HOME/.bashrc" || echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$HOME/rplidar_sdk/output/Linux/Release" >> "$HOME/.bashrc"
source "$HOME/.bashrc" || log_failure ".bashrc 적용 실패"
retry_cmd ldconfig || log_failure "ldconfig 실행 실패"
echo "RPlidar SDK 설치 완료."

echo "SLAMNAV2 관련 의존성 및 SDK 설치 단계 완료."

##########################
# 5. 최종 오류 요약
##########################
echo "-------------------------------------"
if [ ${#FAILURES[@]} -ne 0 ]; then
    echo "설치 과정 중 다음 항목들이 여전히 실패했습니다:"
    for err in "${FAILURES[@]}"; do
         echo " - $err"
    done
    echo "-------------------------------------"
    echo "일부 설치 항목에 실패하였습니다. 설치 로그를 확인하세요."
else
    echo "모든 설치 작업이 성공적으로 완료되었습니다."
fi

echo "스크립트 종료."

