#!/bin/bash

# SLAMNAV2 - update

echo "SLAMNAV2 업데이트를 진행합니다."

#!/bin/bash

# GitHub 사용자명과 저장소명 설정
OWNER="rainbow-mobile"
REPO="app_slamnav2"

# GitHub API URL 설정 (태그 목록)
API_URL="https://api.github.com/repos/$OWNER/$REPO/git/refs/tags"

# 환경 변수에서 토큰 가져오기
TOKEN="your token"

# 토큰이 설정되어 있는지 확인
if [ -z "$TOKEN" ]; then
    echo "오류: GITHUB_TOKEN 환경 변수가 설정되어 있지 않습니다."
    exit 1
fi

# 인증 헤더를 사용하여 태그 목록 가져오기
TAGS_DATA=$(curl -s -H "Authorization: token $TOKEN" $API_URL)

# API 응답에서 오류 메시지 확인
API_MESSAGE=$(echo "$TAGS_DATA" | jq -r '.message // empty')
if [ ! -z "$API_MESSAGE" ]; then
    echo "API 오류 발생: $API_MESSAGE"
    exit 1
fi

# 최신 태그 가져오기
LATEST_TAG=$(echo "$TAGS_DATA" | jq -r '.[-1].ref' | sed 's|refs/tags/||')

if [ -z "$LATEST_TAG" ]; then
    echo "태그를 찾을 수 없습니다."
    exit 1
fi

echo "최신 태그: $LATEST_TAG"

# 최신 태그의 소스 코드 다운로드 (zip 파일)
ZIP_URL="https://github.com/$OWNER/$REPO/archive/refs/tags/$LATEST_TAG.zip"

echo "다운로드 중: $ZIP_URL"

wget --header="Authorization: token $TOKEN" -O "$REPO-$LATEST_TAG.zip" "$ZIP_URL"

echo "다운로드가 완료되었습니다."

echo "SLAMNAV2 업데이트가 완료 되었습니다."
echo "모든 업데이트가 완료되었습니다."

