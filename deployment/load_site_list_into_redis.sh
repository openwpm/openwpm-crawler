#!/usr/bin/env bash
set -e

if [[ "$REDIS_HOST" == "" ]]; then
    echo "The env var REDIS_HOST needs to be set with the IP/hostname of the managed Redis instance" >&2
    echo "Assuming we are testing locally and setting REDIS_HOST to localhost." >&2
    REDIS_HOST="localhost"
fi

if [[ $# -lt 2 ]]; then
    echo "Usage: load_site_list_into_redis.sh redis_queue_name site_list_csv" >&2
    exit 1
fi
REDIS_QUEUE_NAME="$1"
SITE_LIST_CSV="$2"

echo -e "\nEnqueuing site list in redis"

# Make sure to clear the queue before adding our site list
echo "DEL $REDIS_QUEUE_NAME" > joblist.txt
echo "DEL $REDIS_QUEUE_NAME:processing" >> joblist.txt
echo "DEL $REDIS_QUEUE_NAME:retries" >> joblist.txt

# tr #1 = Remove dos-style line endings which appears in some lists
# sed #1 = Add site list in reverse order since the queue gets worked upon from the bottom up
# sed #2 = Quote single quotes
# awk #1 = Add the RPUSH command with the site value within single quotes
cat "$SITE_LIST_CSV" | tr -d '\r' | sed '1!G;h;$!d' | sed "s/'/\\\'/g" | awk -F ',' 'FNR > 0 {print "RPUSH '$REDIS_QUEUE_NAME' '\''"$1","$2"'\''"}' >> joblist.txt

kubectl cp joblist.txt redis-box:/tmp/joblist.txt
kubectl exec redis-box -- sh -c "cat /tmp/joblist.txt | redis-cli -h $REDIS_HOST --pipe"

rm joblist.txt
