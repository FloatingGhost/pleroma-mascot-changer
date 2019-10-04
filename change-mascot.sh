#!/usr/bin/env bash
set -euxo pipefail

if [ $# -ne 4 ]; then
    echo "usage: change-mascot.sh <instance_url> <username> <password> <image_file>"
    exit 1
fi

INSTANCE_URL=$1
USERNAME=$2
PASSWORD=$3
FILE=$4

USERAGENT="mascotthing"

RESP=$(curl \
    -XPOST \
    $1/api/v1/apps \
    --data-urlencode 'client_name=mascot-script' \
    --data-urlencode 'redirect_uris=urn:ietf:wg:oauth:2.0:oob' \
    --data-urlencode 'scopes=read write follow' \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --header "User-Agent: $USERAGENT")

client_id=$(echo $RESP | jq .client_id | sed "s|\"||g")
client_secret=$(echo $RESP | jq .client_secret | sed "s|\"||g")

RESP=$(curl \
    -XPOST \
    $1/oauth/token \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --header "User-Agent: $USERAGENT" \
    --data-urlencode "client_id=$client_id" \
    --data-urlencode "client_secret=$client_secret" \
    --data-urlencode "username=$USERNAME" \
    --data-urlencode "password=$PASSWORD" \
    --data-urlencode "grant_type=password" \
    --data-urlencode "scope=read write follow"
)

access_token="Bearer $(echo $RESP | jq .access_token | sed "s|\"||g")"

curl \
    -XPUT \
    $1/api/v1/pleroma/mascot \
    --header "Authorization: $access_token" \
    -F "file=@$FILE"

echo "Changed!"
