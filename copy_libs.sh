#!/usr/bin/env bash

# 사용법: copy_libs.sh <실행파일 경로> <복사 대상 디렉터리>
# 예시:  ./copy_libs.sh ./SLAMNAV2 /tmp/my_libs

if [ $# -lt 2 ]; then
  echo "Usage: $0 <executable> <destination-folder>"
  exit 1
fi

EXECUTABLE="$1"
DESTINATION="$2"

# 복사 대상 디렉토리가 없으면 생성
mkdir -p "$DESTINATION"

# 실행 파일도 함께 복사하고 싶다면 추가
# cp "$EXECUTABLE" "$DESTINATION"

# ldd 결과에서 라이브러리 경로만 추출
LIBS=$(ldd "$EXECUTABLE" \
  | grep "=>" \
  | grep -v "not found" \
  | sed 's/.*=> \(.*\) (.*/\1/' \
  | sort -u)

echo "====== Detected Libraries ======"
echo "$LIBS"
echo "================================"

# 라이브러리들을 대상 디렉토리로 복사
# --no-clobber 옵션(-n) 등을 사용하면 이미 존재하는 파일은 덮어쓰지 않습니다 (원하면 사용).
# 심볼릭 링크를 풀어서 복사하려면 cp -L 등으로 대체 가능.
for lib in $LIBS; do
  echo "Copying $lib -> $DESTINATION"
  cp -v "$lib" "$DESTINATION"
done

echo "All done."

