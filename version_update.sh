#!/bin/bash

# SLAMNAV2 - 업데이트

echo "SLAMNAV2 업데이트를 진행합니다."

# GitHub 사용자명과 저장소명 설정
OWNER="rainbow-mobile"
REPO="app_slamnav2"

# 환경 변수에서 토큰 가져오기
TOKEN="your_token"

# 토큰이 설정되어 있는지 확인
if [ -z "$TOKEN" ]; then
    echo "오류: GITHUB_TOKEN 환경 변수가 설정되어 있지 않습니다."
    exit 1
fi

# 최신 태그 가져오기
TAG_API_URL="https://api.github.com/repos/$OWNER/$REPO/git/refs/tags"
TAGS_DATA=$(curl -s -H "Authorization: token $TOKEN" $TAG_API_URL)

# API 응답에서 오류 메시지 확인
API_MESSAGE=$(echo "$TAGS_DATA" | jq -r '.message // empty')
if [ ! -z "$API_MESSAGE" ]; then
    echo "API 오류 발생 (태그 목록): $API_MESSAGE"
    exit 1
fi

# 최신 태그 가져오기
LATEST_TAG=$(echo "$TAGS_DATA" | jq -r '.[-1].ref' | sed 's|refs/tags/||')

if [ -z "$LATEST_TAG" ]; then
    echo "태그를 찾을 수 없습니다."
    exit 1
fi

echo "최신 태그: $LATEST_TAG"

# 해당 태그와 동일한 이름의 릴리스 검색
RELEASE_API_URL="https://api.github.com/repos/$OWNER/$REPO/releases/tags/$LATEST_TAG"
RELEASE_DATA=$(curl -s -H "Authorization: token $TOKEN" $RELEASE_API_URL)

# 릴리스 API 응답 출력 (디버깅 용도)
echo "릴리스 API 응답:"
echo "$RELEASE_DATA"

# 릴리스가 존재하는지 확인
API_MESSAGE=$(echo "$RELEASE_DATA" | jq -r '.message // empty')
if [ "$API_MESSAGE" == "Not Found" ]; then
    echo "태그 '$LATEST_TAG'에 대한 릴리스를 찾을 수 없습니다. 릴리스를 생성해주세요."
    exit 1
elif [ ! -z "$API_MESSAGE" ]; then
    echo "API 오류 발생 (릴리스 검색): $API_MESSAGE"
    exit 1
fi

# "Source code"를 제외한 Asset의 다운로드 URL 추출
#ASSET_URLS=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | test("Source code") | not) | .browser_download_url')

 다운로드할 Asset이 있는지 확인
if [ -z "$ASSET_URLS" ]; then
    echo "다운로드할 Asset이 없습니다."
    exit 1
fi

# 각 Asset 다운로드
for URL in $ASSET_URLS; do
    echo "다운로드 중: $URL"
    wget --header="Authorization: token $TOKEN" -N "$URL"
done

echo "SLAMNAV2 업데이트가 완료되었습니다."

