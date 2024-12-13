#!/bin/bash

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

# 6. Restart the system
echo "All tasks are completed. The system need reboot."
sudo reboot

