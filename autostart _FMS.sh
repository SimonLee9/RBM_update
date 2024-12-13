#!/bin/bash

# RB_FMS 자동 재시작 스크립트

# 실행 중인지 확인하는 함수
is_running() {
    pgrep -f RB_FMS > /dev/null 2>&1
    return $?
}

# RB_FMS 실행 및 모니터링
while true; do
    if ! is_running; then
        echo "RB_FMS is not running. Starting RB_FMS..."
        # Home 디렉토리로 이동하여 RB_FMS 실행
        cd ~
        ./RB_FMS &
        sleep 5  # 프로세스가 제대로 시작할 시간을 줍니다.
    else
        echo "RB_FMS is running."
    fi
    sleep 10  # 10초마다 프로세스 상태를 확인
done

exit 0

