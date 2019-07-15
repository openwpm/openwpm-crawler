#!/usr/bin/env bash
set -e

if [[ $# -lt 2 ]]; then
    echo "Usage: load_site_list_into_redis.sh redis_queue_name site_list_csv" >&2
    exit 1
fi
REDIS_QUEUE_NAME="$1"
SITE_LIST_CSV="$2"

cat "$SITE_LIST_CSV" | sed "s/^/RPUSH $REDIS_QUEUE_NAME /" > joblist.txt
kubectl cp joblist.txt redis-master:/tmp/joblist.txt

echo -e "\nEnqueuing site list in redis"
kubectl exec redis-master -- sh -c "cat /tmp/joblist.txt | redis-cli --pipe"

rm joblist.txt
