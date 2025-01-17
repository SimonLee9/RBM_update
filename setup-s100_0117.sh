#!/bin/bash


# 1번 - bashrc
# /etc/profile에 환경 변수 추가
sudo sh -c 'echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib" >> /etc/profile'
sudo sh -c 'echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/rplidar_sdk/output/Linux/Release" >> /etc/profile'
#sudo sh -c 'echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/lib" >> /etc/profile'
sudo sh -c 'echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/lib" >> /etc/profile'

# 프로필 재적용
source /etc/profile

# 라이브러리 캐시 업데이트
sudo ldconfig

# 2번 (USB 전원 해제)
# /etc/default/grub 파일 수정하여 usbcore.autosuspend=-1 추가
sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ usbcore.autosuspend=-1 intel_pstate=disable"/' /etc/default/grub

# GRUB 업데이트
sudo update-grub


# 자동 업데이트 설정 비활성화
sudo sh -c 'cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF'

# 새로운 우분투 버전 알림 설정: Never
sudo sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades

# gsettings를 사용하여 자동 업데이트 확인 주기를 Never로 설정
gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0

echo "환경 설정이 완료되었습니다."

# 0. Qt lib install 

sudo apt-get install qtmultimedia5-dev -y

# 1. Reset TeamViewer
echo "Resetting TeamViewer..."
sudo teamviewer --daemon stop

sudo rm -f /etc/teamviewer/global.conf
sudo rm -rf ~/.config/teamviewer/

sudo teamviewer --daemon start
echo "TeamViewer reset complete."

# 2. Install rplidar SDK
echo "Installing rplidar SDK..."
cd ~  # Go to the home directory

if [ -d "rplidar_sdk" ]; then
    echo "rplidar_sdk directory already exists. Pulling the latest changes."
    cd rplidar_sdk
    git pull
else
    git clone https://github.com/Slamtec/rplidar_sdk.git
    cd rplidar_sdk
fi

make
echo "rplidar SDK installation complete."

# 3. Update Orbbec SDK
echo "Updating Orbbec SDK..."
cd ~/OrbbecSDK

git pull
git checkout v1.10.11

cd build/install/scripts

sudo bash install_udev_rules.sh
#echo "Orbbec SDK update complete."

# 4. USB Settings
echo "Configuring USB settings..."
sudo adduser "$USER" dialout

sudo bash -c 'cat > /etc/udev/rules.d/99-usb-serial.rules <<EOF
SUBSYSTEM=="tty", KERNELS=="1-7", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="ttyRP0"
SUBSYSTEM=="tty", KERNELS=="1-2.3", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="ttyBL0"
EOF'

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger
echo "USB settings configured."

# 5. Switch back to the main branch
echo "Switching back to the main branch..."
cd ~/OrbbecSDK
git checkout main
echo "Switched to the main branch."


sudo apt install dkms

git clone https://github.com/gnab/rtl8812au.git

sudo cp -r rtl8812au /usr/src/rtl8812au-4.2.2

sudo dkms add -m rtl8812au -v 4.2.2

sudo dkms build -m rtl8812au -v 4.2.2

sudo dkms install -mrtl8812au -v 4.2.2

sudo modprobe 8812au


# 6. Restart the system
echo "All tasks are completed. The system need reboot."
sudo reboot

