#!/bin/bash

# 1번 - bashrc
# /etc/profile에 환경 변수 추가
sudo sh -c 'echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/lib" >> /etc/profile'
sudo sh -c 'echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/rplidar_sdk/output/Linux/Release" >> /etc/profile'
sudo sh -c 'echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/home/rainbow/OrbbecSDK/lib/linux_x64" >> /etc/profile'

# 프로필 재적용
source /etc/profile

# 라이브러리 캐시 업데이트
sudo ldconfig


echo "환경 설정이 완료되었습니다."

