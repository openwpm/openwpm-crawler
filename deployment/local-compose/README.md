# Run a local OpenWPM crawl using Docker Compose

Documentation and scripts to launch an OpenWPM crawl using Docker Compose locally.

## Prerequisites

Install Docker and Docker Compose. Note that
Docker for Mac & Windows include Docker Compose


For the remainder of these instructions, you are assumed to be in the `deployment/local-compose/` folder.

## Build Docker image

Make sure that you have an up to date docker image locally:

```
docker pull openwpm/openwpm
docker tag openwpm/openwpm openwpm
```

Alternatively, you can build the image from a local OpenWPM code repository:

```
cd path/to/OpenWPM
docker build -t openwpm .
cd -
```
## Set up a mock S3 service

```
docker-compose up -d localstack
```

## Deploy the redis server which we use for the work queue

```
docker-compose up -d redis
```

## Adding sites to be crawled to the queue

First set the REDIS_HOST enviroment variable:
```
export REDIS_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker-compose ps -q redis))
```
Create a comma-separated site list as per:

```
echo "1,http://www.example.com
2,http://www.example.org
3,http://www.princeton.edu
4,http://citp.princeton.edu/" > site_list.csv

../load_site_list_into_redis.sh crawl-queue site_list.csv 
```

(Optional) To load Alexa Top 1M into redis:

```
cd ..; ./load_alexa_top_1m_site_list_into_redis.sh crawl-queue; cd -
```

You can also specify a max rank to load into the queue. For example, to add the
top 1000 sites from the Alexa Top 1M list:

```
cd ..; ./load_alexa_top_1m_site_list_into_redis.sh crawl-queue 1000; cd -
```

(Optional) Use some of the `../../utilities/crawl_utils.py` code. For instance, to fetch and store a sample of Alexa Top 1M to `/tmp/sampled_sites.json`:
```
source ../../venv/bin/activate
cd ../../; python -m utilities.get_sampled_sites; cd -
```

### Monitor Job

#### Queue status

Open a temporary instance and launch redis-cli:
```
docker exec -it $(docker-compose ps -q redis) sh -c "redis-cli -h localhost"
```

Current length of the queue:
```
llen crawl-queue
```

Amount of queue items marked as processing:
```
llen crawl-queue:processing 
```

Contents of the queue:
```
lrange crawl-queue 0 -1
lrange crawl-queue:processing 0 -1
```

#### Job status

```
    docker-compose ps
```

#### View Job logs

To watch all output from all running containers continuously 
```
    docker-compose logs -f
```

### Inspecting crawl results
UNTESTED
When it has completed, run:
```
export LOCALSTACK_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker-compose ps -q localstack))

s3cmd --verbose --access_key=foo --secret_key=foo --host=http://$LOCALSTACK_IP:32001 --host-bucket=localhost --no-ssl sync --delete-removed s3://localstack-foo local-crawl-results/data
```

The crawl data will end up in Parquet format in `./local-crawl-results/data`

### Clean up created pods, services and local artifacts

```
docker-compose down
```
