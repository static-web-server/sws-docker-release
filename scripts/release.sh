#!/usr/bin/env bash

set -e

echo "Creating a Github release..."

if [[ "$GITHUB_TOKEN" == "" ]]; then
  echo "Please provide GitHub access token via GITHUB_TOKEN environment variable!"
  exit 1
fi

RETRIES=0
until [ $RETRIES -eq 20 ]
do
  echo "Finding the release associated with this tag..."
  CIRRUS_RELEASE=$(curl -sL -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$CIRRUS_REPO_FULL_NAME/releases | jq -c "[ .[] | select( .tag_name | contains(\"$CIRRUS_TAG\")) ] | .[0]" | jq -r '.id')
  [[ "$CIRRUS_RELEASE" != "null" ]] && break
  RETRIES=$((RETRIES+1))
  sleep 30
done


if [[ "$CIRRUS_RELEASE" == "null" ]]; then
    echo "Failed to find the associated '$CIRRUS_TAG' release!"
    exit 1
fi

echo "Github release '$CIRRUS_TAG' found. Preparing asset files to upload..."

file_content_type="application/octet-stream"
files_to_upload=(
  static-web-server-$CIRRUS_TAG-i686-unknown-freebsd.tar.gz
  static-web-server-$CIRRUS_TAG-x86_64-unknown-freebsd.tar.gz
)

for fpath in $files_to_upload
do
  echo "Uploading Github release asset $fpath..."
  name=$(basename "$fpath")
  url_to_upload="https://uploads.github.com/repos/$CIRRUS_REPO_FULL_NAME/releases/$CIRRUS_RELEASE/assets?name=$name"
  curl -X POST \
    --data-binary @$fpath \
    --header "Authorization: token $GITHUB_TOKEN" \
    --header "Content-Type: $file_content_type" \
    $url_to_upload
done

echo
echo "Github release assets uploaded successfully."
