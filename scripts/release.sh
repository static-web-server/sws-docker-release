#!/usr/bin/env bash

echo "Creating a Github release..."

if [[ "$GITHUB_TOKEN" == "" ]]; then
  echo "Please provide GitHub access token via GITHUB_TOKEN environment variable!"
  exit 1
fi

RETRIES=0
until [ $RETRIES -eq 20 ]
do
  echo "Retrying to find a release associated with this tag"
  CIRRUS_RELEASE=$(curl -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$CIRRUS_REPO_FULL_NAME/releases/tags/$CIRRUS_TAG | jq -c "[ .[] | select( .tag_name | contains(\"$CIRRUS_TAG\")) ]|.[1]" | jq -r '.id')
  [[ "$CIRRUS_RELEASE" != "null" ]] && break
  RETRIES=$((RETRIES+1))
  sleep 30
done

if [[ "$CIRRUS_RELEASE" == "null" ]]; then
    echo "Failed to find a release associated with this tag!"
    echo "No Github release found. Nothing to deploy!"
    exit 0
fi

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
echo "Releases published successfully."
