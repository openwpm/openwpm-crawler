#!/bin/bash
set -e
docker-compose up -d redis localstack
export REDIS_CONTAINER=$(docker-compose ps -q redis)
cd ..
./load_alexa_top_1m_site_list_into_redis.sh crawl-queue 100
cd -