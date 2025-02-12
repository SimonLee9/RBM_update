#!/usr/bin/env bash

# copy_libs_recur.sh
# ------------------
# 사용법:
#   ./deploy2.sh <executable_path> <destination_folder>
#
# 예시:
#   ./deploy2.sh /home/lee/code/build-SLAMNAV2-Desktop-Release/SLAMNAV2 /home/lee/code/slamnav2
#
# 설명:
#   1) <executable_path> 및 그 실행 파일이 의존하는 라이브러리를 재귀적으로 조사(ldd).
#   2) 대상 디렉토리에 라이브러리(.so) 파일을 전부 복사. (이미 복사된 것은 중복 방지)
#   3) ldd 결과에 잡히지 않는 동적 로딩(dlopen) 라이브러리는 누락될 수 있음.

set -e  # 스크립트 에러 시 즉시 종료를 원하는 경우 사용 (선택)

if [ $# -lt 2 ]; then
  echo "Usage: $0 <executable> <destination-folder>"
  echo "Example: $0 /home/lee/code/build-SLAMNAV2-Desktop-Release/SLAMNAV2 /home/lee/code/slamnav2"
  exit 1
fi

EXECUTABLE="$1"
DESTINATION="$2"

# 복사 대상 디렉토리 생성
mkdir -p "$DESTINATION"

# 이미 복사된 라이브러리 경로를 기록할 배열/해시
# (bash 4 이상에서 사용 가능한 associative array)
declare -A COPIED_LIBS

function copy_deps() {
    local bin="$1"
    
    # ldd로 bin이 의존하는 라이브러리 경로들을 추출
    # ldd 출력 예: "libSomething.so => /usr/lib/libSomething.so (0x...)" 형태에서
    # 실제 경로(/usr/lib/libSomething.so)만 얻기 위해 awk와 grep을 사용
    local deps
    deps=$(ldd "$bin" 2>/dev/null \
            | awk '/=>/ {print $3}' \
            | grep -v '^(' \
            | sort -u)

    for dep in $deps; do
        # dep가 비어있지 않고, 실제 파일일 경우만 처리
        if [ -n "$dep" ] && [ -f "$dep" ]; then
            # 아직 복사하지 않은 라이브러리라면
            if [ -z "${COPIED_LIBS[$dep]}" ]; then
                echo "[*] Copying $dep -> $DESTINATION"
                
                # 심볼릭 링크를 실제 파일로 복사하고 싶다면: cp -L
                # 심볼릭 링크 자체로만 복사하고 싶다면:     cp
                cp -v "$dep" "$DESTINATION"

                # 복사 완료 표시
                COPIED_LIBS["$dep"]=1

                # 재귀 호출하여, 방금 복사한 라이브러리가 의존하는 라이브러리도 계속 추적
                copy_deps "$dep"
            fi
        fi
    done
}

echo "====== Recursively copying libraries for: $EXECUTABLE ======"
# (선택) 실행 파일 자체를 대상 폴더에 복사하고 싶다면 아래 주석 해제
# cp -v "$EXECUTABLE" "$DESTINATION"

# 메인 실행 파일에 대해 재귀 함수 호출
copy_deps "$EXECUTABLE"

echo "====== All done. ======"
echo "Copied libraries to: $DESTINATION"

