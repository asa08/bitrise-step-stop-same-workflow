#!/usr/bin/env bash
# fail if any commands fails
set -e
# debug log
set -x

if hash jq 2>/dev/null; then
  echo "jq already installed."
else
  echo "jq is not installed. Installing..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew install jq
fi

# 現在のビルドのPR番号を取得します
CURRENT_PR_NUMBER=$(curl -H "Authorization: ${bitrise_access_token}" https://api.bitrise.io/v0.1/apps/$bitrise_app_slug/builds/$bitrise_build_slug | jq -r '.data.pull_request_id')
# 同じアプリのすべての実行中のビルドを取得します
RUNNING_BUILDS=$(curl -H "Authorization: ${bitrise_access_token}" https://api.bitrise.io/v0.1/apps/$bitrise_app_slug/builds?status=0&workflow=$workflow)
# 現在のビルドと同じPRを自分以外すべてのビルドをキャンセルします
for BUILD_SLUG in $(echo $RUNNING_BUILDS | jq -r '.data[] | select(.slug != "'$bitrise_build_slug'" and .pull_request_id == '$CURRENT_PR_NUMBER') | .slug'); do
    curl -X 'POST' \
      https://api.bitrise.io/v0.1/apps/$bitrise_app_slug/builds/$BUILD_SLUG/abort \
      -H "Authorization: ${bitrise_access_token}" \
      -H "accept: application/json" \
      -H "Content-Type: application/json" \
      -d '{
           "abort_reason": "新しいPRを出したため",
           "abort_with_success": true,
           "skip_notifications": true
          }'
done
