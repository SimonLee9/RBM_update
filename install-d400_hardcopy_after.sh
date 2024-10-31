#!/bin/bash

# Node.js 환경설치 스크립트

# 오류 발생 시 스크립트 중지
set -e

# 업데이트 및 curl 설치
echo "업데이트 및 curl 설치"
sudo apt-get update
sudo apt-get install -y curl


# nvm(노드 버전관리자) 설치
echo "nvm(노드 버전관리자) 설치"

#curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# nvm이 이미 설치되어 있는지 확인
if command -v nvm >/dev/null 2>&1; then
    echo "nvm이 이미 설치되어 있습니다. 설치를 건너뜁니다."
else
    echo "nvm이 설치되어 있지 않습니다. 설치를 진행합니다."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

    # nvm 환경변수 로드
    echo "nvm 환경변수 로드"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi



# nvm 환경변수 로드
echo "nvm 환경변수 로드"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Node.js와 npm 설치
echo "Node.js와 npm 설치"

nvm install --lts
nvm use --lts

# npm 최신화
echo "npm 최신화"

npm install -g npm@latest

# Node.js 버전 확인
echo "Node.js 버전 확인"

node --version

# Git 계정 설정 (필요 시 주석 해제하여 사용)
# git config --global user.name "your_username"
# git config --global user.password "your_password"


# MobileServer 설치
echo "MobileServer 설치"
cd ~
#git clone https://github.com/rainbow-mobile/web_robot_server.git
#cd web_robot_server
#npm install #(up to date 뜨면 ok. added packages 뜨면 ok. severity vulnerability(보안경고) 있으면 npm audit fix)
if [ -d "web_robot_server" ]; then
    echo "web_robot_server 디렉토리가 이미 존재합니다. 클론을 건너뜁니다."
else
    git clone https://github.com/rainbow-mobile/web_robot_server.git
fi
cd web_robot_server
npm install #(up to date 뜨면 ok. added packages 뜨면 ok. severity vulnerability(보안경고) 있으면 npm audit fix)


## MobileServer 실행 (백그라운드 실행 및 재시작 설정)
#echo "MobileServer 실행 (백그라운드 실행 및 재시작 설정)"

#sudo npm install -g pm2
#pm2 start src/server.js
#pm2 save

## pm2 startup 명령의 출력 결과에 따라 추가 명령 실행 필요
#pm2 startup | tail -n 1 | sudo bash

# MobileWeb 설치
echo "MobileWeb 설치"

cd ~
#git clone https://github.com/rainbow-mobile/web_robot_ui.git
if [ -d "web_robot_ui" ]; then
    echo "web_robot_ui 디렉토리가 이미 존재합니다. 클론을 건너뜁니다."
else
    git clone https://github.com/rainbow-mobile/web_robot_ui.git
fi
cd web_robot_ui # (added packages 뜨면 ok.)
npm install 
npm run build

## MobileWeb 실행
#echo "MobileWeb 실행"

#npm run start &

# 방화벽 포트 해제
echo "방화벽 포트 해제"

sudo ufw allow 8180    # MobileWeb
sudo ufw allow 11334   # MobileServer
sudo ufw allow 11337   # MobileServer
sudo ufw allow 11338   # MobileServer
sudo ufw allow 10334   # MobileServer

# TaskMan 설치에 필요한 패키지 설치
echo "TaskMan 설치에 필요한 패키지 설치"
sudo apt-get install -y flex bison

# TaskMan 클론 및 빌드
echo "TaskMan 클론 및 빌드"
cd ~
#git clone https://github.com/rainbow-mobile/app_taskman.git
if [ -d "app_taskman" ]; then
    echo "app_taskman 디렉토리가 이미 존재합니다. 클론을 건너뜁니다."
else
    git clone https://github.com/rainbow-mobile/app_taskman.git
fi


# 빌드 디렉토리 생성 및 빌드 (필요한 경우 추가 명령어를 작성하세요)
echo "빌드 디렉토리 생성 및 빌드"
cd app_taskman
#mkdir build && cd build
if [ ! -d "build" ]; then
    mkdir build
fi
cd build
cmake ..
make


# Sudo 설정 (nmcli 명령어에 비밀번호 없이 접근 가능하도록 설정)
echo "Sudo 설정 (nmcli 명령어에 비밀번호 없이 접근 가능하도록 설정)"
#echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/nmcli" | sudo tee -a /etc/sudoers

if sudo grep -Fxq "$USER ALL=(ALL) NOPASSWD: /usr/bin/nmcli" /etc/sudoers; then
    echo "sudoers에 이미 설정이 존재합니다. 건너뜁니다."
else
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/nmcli" | sudo tee -a /etc/sudoers
fi


## Sudo setting 
# sudo visudo
# 마지막 라인에 추가
# rainbow ALL=(ALL) NOPASSWD: /usr/bin/nmcli


echo "node.js 환경설치 완료"

############################### DB 환경 설치 스크립트 (mobile) ###############################


# MySQL 서버 설치
#sudo apt-get update
echo "MySQL 서버 설치"
sudo apt-get install -y mysql-server

# 보안 설정
echo "보안 설정"
sudo mysql_secure_installation

# MySQL 보안 설정 자동화
echo "MySQL 보안 설정 자동화"
# 비밀번호 및 설정을 자동화하기 위해 expect를 사용합니다.
sudo apt-get install -y expect

# MySQL 루트 비밀번호 설정 (사용자 입력)
read -sp "설정할 MySQL 루트 비밀번호를 입력하세요: " MYSQL_ROOT_PASSWORD
echo

# mysql_secure_installation 자동화 스크립트
SECURE_MYSQL=$(expect -c "

set timeout 10
spawn sudo mysql_secure_installation

expect \"Press y|Y for Yes, any other key for No:\"
send \"y\r\"

expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
send \"0\r\"

expect \"Change the password for root ? ((Press y|Y for Yes, any other key for No) :\"
send \"n\r\"

expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
send \"n\r\"

expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect eof
")

echo "$SECURE_MYSQL"

# MySQL 루트 사용자 인증 방식 변경 및 비밀번호 설정
sudo mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
EXIT;
EOF

# MySQL 접속 테스트
echo "MySQL에 접속하여 설정을 적용합니다..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
-- 비밀번호 정책 설정
SET GLOBAL validate_password.length = 4;
SET GLOBAL validate_password.policy = LOW;

-- 초기 데이터베이스 생성 및 테이블 생성
CREATE DATABASE IF NOT EXISTS versiondb DEFAULT CHARACTER SET UTF8;
USE versiondb;
CREATE TABLE IF NOT EXISTS curversion(
    program VARCHAR(32) NOT NULL PRIMARY KEY,
    date DATETIME(3) NOT NULL DEFAULT NOW(3) ON UPDATE NOW(3),
    version VARCHAR(32) NOT NULL,
    prev_version VARCHAR(32)
);
CREATE TABLE IF NOT EXISTS log_SLAMNAV2(
    date DATETIME(3) NOT NULL DEFAULT NOW(3),
    new_version VARCHAR(32) NOT NULL,
    prev_version VARCHAR(32),
    result VARCHAR(32) NOT NULL
);
CREATE TABLE IF NOT EXISTS log_MobileServer(
    date DATETIME(3) NOT NULL DEFAULT NOW(3),
    new_version VARCHAR(32) NOT NULL,
    prev_version VARCHAR(32),
    result VARCHAR(32) NOT NULL
);
CREATE TABLE IF NOT EXISTS log_MobileWeb(
    date DATETIME(3) NOT NULL DEFAULT NOW(3),
    new_version VARCHAR(32) NOT NULL,
    prev_version VARCHAR(32),
    result VARCHAR(32) NOT NULL
);
CREATE TABLE IF NOT EXISTS log_TaskMan(
    date DATETIME(3) NOT NULL DEFAULT NOW(3),
    new_version VARCHAR(32) NOT NULL,
    prev_version VARCHAR(32),
    result VARCHAR(32) NOT NULL
);

CREATE DATABASE IF NOT EXISTS logdb DEFAULT CHARACTER SET UTF8;
USE logdb;
CREATE TABLE IF NOT EXISTS state(
    time DATETIME(3) NOT NULL DEFAULT NOW(3),
    state VARCHAR(32) NOT NULL,
    auto_state VARCHAR(32) NOT NULL,
    localization VARCHAR(32) NOT NULL,
    power TINYINT(1) NOT NULL,
    emo TINYINT(1) NOT NULL,
    obs_state VARCHAR(32) NOT NULL,
    charging TINYINT(1) NOT NULL,
    inlier_ratio DOUBLE NOT NULL,
    inlier_error DOUBLE NOT NULL
);
CREATE TABLE IF NOT EXISTS power(
    time DATETIME(3) NOT NULL DEFAULT NOW(3),
    battery_in DOUBLE NOT NULL,
    battery_out DOUBLE NOT NULL,
    battery_current DOUBLE NOT NULL,
    power DOUBLE NOT NULL,
    total_power DOUBLE NOT NULL,
    motor0_temp DOUBLE NOT NULL,
    motor0_current DOUBLE NOT NULL,
    motor0_status INT NOT NULL,
    motor1_temp DOUBLE NOT NULL,
    motor1_current DOUBLE NOT NULL,
    motor1_status INT NOT NULL
);
EXIT;
EOF

echo "데이터베이스와 테이블 생성이 완료되었습니다."


echo "pm 자동실행 - 설치 시작."

# 홈 디렉토리로 이동
cd ~

# pm2 전역 설치
sudo npm install -g pm2

# pm2를 사용하여 서비스 시작
# MobileServer 실행 (작업 디렉토리 설정)
pm2 start --cwd ~/web_robot_server src/server.js --name "MobileServer"

# SLAMNAV2 실행
pm2 start ~/slamnav2/SLAMNAV2 --name "SLAMNAV2"

# TaskMan 실행 (작업 디렉토리 설정)
pm2 start --cwd ~/taskman TaskMan --name "TaskMan"

# MobileWeb UI 실행 (npm start를 사용하여 실행)
pm2 start npm --name "MobileWebUI" --cwd ~/web_robot_ui -- start

# pm2 프로세스 리스트 저장
pm2 save

# pm2를 부팅 시 자동으로 실행되도록 설정
# pm2 startup 명령의 출력 결과에 따라 추가 명령 실행 필요
PM2_STARTUP_CMD=$(pm2 startup | tail -n 1)
eval $PM2_STARTUP_CMD

echo "pm2 서비스를 설정하고 부팅 시 자동 실행되도록 구성하였습니다."

echo "환경 설정이 완료되었습니다."

