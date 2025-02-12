#!/usr/bin/env bash

# copy_libs.sh
# 사용법:
#   /home/code/RBM_update/copy_libs.sh <executable_path> <destination_folder>
#
# 예시:
#   /home/code/RBM_update/copy_libs.sh /home/code/build-SLAMNAV2-Desktop-Release/SLAMNAV2 /home/code/slamnav2
#
# 설명:
#   1) 첫 번째 인자(<executable_path>)는 라이브러리를 추출할 실행 파일 경로입니다.
#   2) 두 번째 인자(<destination_folder>)는 복사할 라이브러리들을 저장할 목적지 폴더 경로입니다.

if [ $# -lt 2 ]; then
  echo "Usage: $0 <executable> <destination-folder>"
  echo "Example: $0 /home/lee/code/build-SLAMNAV2-Desktop-Release/SLAMNAV2 /home/lee/code/slamnav2"
  exit 1
fi

EXECUTABLE="$1"
DESTINATION="$2"

# 복사 대상 디렉토리가 없으면 생성
mkdir -p "$DESTINATION"

# (필요시) 실행 파일도 함께 복사하려면 아래 주석 해제
cp "$EXECUTABLE" "$DESTINATION"

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
# 이미 존재하는 파일은 덮어쓰지 않으려면 --no-clobber(-n) 옵션 사용 가능
# 심볼릭 링크를 실제 파일로 복사하려면 cp -L 옵션 사용
for lib in $LIBS; do
  echo "Copying $lib -> $DESTINATION"
  cp -v "$lib" "$DESTINATION"
done

echo "All done."

