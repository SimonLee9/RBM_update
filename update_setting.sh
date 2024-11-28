#!/bin/bash


# 1번 (bashrc)
# /etc/profile에 환경 변수 추가
sudo sh -c 'echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib" >> /etc/profile'
sudo sh -c 'echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/rplidar_sdk/output/Linux/Release" >> /etc/profile'
sudo sh -c 'echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/lib/linux_x64" >> /etc/profile'

# 프로필 재적용
source /etc/profile

# 라이브러리 캐시 업데이트
sudo ldconfig

# 2번 (USB 절전 모드 해제)
# /etc/default/grub 파일 수정하여 usbcore.autosuspend=-1 추가
sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ usbcore.autosuspend=-1 intel_pstate=disable"/' /etc/default/grub

# GRUB 업데이트
sudo update-grub

# 시스템 재부팅 (필요 시 주석 해제)
# sudo reboot

# 무선 네트워크 전원 관리 비활성화
sudo iwconfig wlo1 power off

# 자동 업데이트 비활성화  (우분투 업데이트 설정 변경)

# 자동 업데이트 확인 주기 설정: Never
sudo sh -c 'echo "APT::Periodic::Update-Package-Lists \"0\";" > /etc/apt/apt.conf.d/10periodic'

# 새로운 우분투 버전 알림 설정: Never
sudo sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades


echo "환경 설정이 완료되었습니다."

