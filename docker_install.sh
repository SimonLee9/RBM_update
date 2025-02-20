#!/bin/bash

# 스크립트 실행 중 오류 발생 시 중단
set -e

# 1. 우분투 시스템 패키지 업데이트
echo "Updating system packages..."
sudo apt-get update

# 2. 필요한 패키지 설치
echo "Installing required packages..."
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

# 3. Docker의 공식 GPG키 추가
echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# 4. Docker의 공식 apt 저장소 추가
echo "Adding Docker repository..."
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# 5. 시스템 패키지 업데이트
echo "Updating system packages again..."
sudo apt-get update

# 6. Docker 설치
echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# 7. Docker가 정상적으로 설치되었는지 확인
echo "Checking Docker status..."
sudo systemctl status docker --no-pager

