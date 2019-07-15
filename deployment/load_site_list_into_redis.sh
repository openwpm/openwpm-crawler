#!/usr/bin/env bash
set -e

if [[ $# -lt 2 ]]; then
    echo "Usage: load_site_list_into_redis.sh redis_queue_name site_list_csv" >&2
    exit 1
fi
REDIS_QUEUE_NAME="$1"
SITE_LIST_CSV="$2"

echo -e "\nEnqueuing site list in redis"

# Make sure to clear the queue before adding our site list
echo "DEL $REDIS_QUEUE_NAME" > joblist.txt

# Add site list in reverse order since the queue gets worked upon from the bottom up
tail -r "$SITE_LIST_CSV" | sed "s/^/RPUSH $REDIS_QUEUE_NAME /" >> joblist.txt
kubectl cp joblist.txt redis-master:/tmp/joblist.txt
kubectl exec redis-master -- sh -c "cat /tmp/joblist.txt | redis-cli --pipe"

rm joblist.txt