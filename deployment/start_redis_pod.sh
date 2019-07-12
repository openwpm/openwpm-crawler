#!/bin/bash
set -e

if [[ $# -lt 1 ]]; then
    echo "Usage: start_redis_pod.sh crawl_name" >&2
    exit 1
fi
CRAWL_NAME=$1

echo -e "\nStarting redis pod..."
kubectl apply -f ./redis-pod.yaml
echo -e "\nStarting redis service..."
kubectl apply -f ./redis-service.yaml

echo -e "\nDownloading and unzipping site list..."
wget http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
unzip -o top-1m.csv.zip
cat top-1m.csv | sed "s/^/RPUSH $CRAWL_NAME /" > joblist.txt
kubectl cp joblist.txt redis-master:/tmp/joblist.txt

echo -e "\nEnqueuing site list in redis"
kubectl exec redis-master -- sh -c "cat /tmp/joblist.txt | redis-cli --pipe"

echo -e "\nCleaning up..."
rm joblist.txt
rm top-1m.csv.zip
rm top-1m.csv
