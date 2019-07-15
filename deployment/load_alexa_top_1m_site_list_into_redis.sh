#!/bin/bash
set -e

if [[ $# -lt 1 ]]; then
    echo "Usage: start_redis_and_load_with_alexa_top_1m.sh redis_queue_name" >&2
    exit 1
fi
REDIS_QUEUE_NAME="$1"

echo -e "\nDownloading and unzipping site list..."
wget http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
unzip -o top-1m.csv.zip

./load_site_list_into_redis.sh "$REDIS_QUEUE_NAME" "top-1m.csv.zip"

echo -e "\nCleaning up..."
rm top-1m.csv.zip
rm top-1m.csv
