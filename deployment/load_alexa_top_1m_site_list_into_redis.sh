#!/bin/bash
set -e

if [[ $# -lt 1 ]]; then
    echo "Usage: load_alexa_top_1m_site_list_into_redis.sh redis_queue_name [max_rank]" >&2
    exit 1
fi
REDIS_QUEUE_NAME="$1"
MAX_RANK="$2"

echo -e "\nAttempting to clean up any leftover lists from a previous run..."
rm top-1m.csv.zip* || true
rm top-1m.csv* || true

echo -e "\nDownloading and unzipping site list..."
wget http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
unzip -o top-1m.csv.zip

if [[ -n "$MAX_RANK" ]]; then
  echo Limiting site list to the top $MAX_RANK items...
  head -n $MAX_RANK top-1m.csv > temp.csv
  mv temp.csv top-1m.csv
fi

./load_site_list_into_redis.sh $REDIS_QUEUE_NAME top-1m.csv

echo -e "\nCleaning up..."
rm top-1m.csv.zip
rm top-1m.csv
