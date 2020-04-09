# Run a local OpenWPM crawl using Docker Compose

Documentation and scripts to launch an OpenWPM crawl using Docker Compose locally.

- [Run a local OpenWPM crawl using Docker Compose](#run-a-local-openwpm-crawl-using-docker-compose)
  - [Prerequisites](#prerequisites)
    - [Build Docker image](#build-docker-image)
    - [Set up a mock S3 service](#set-up-a-mock-s3-service)
    - [Deploy the redis server which we use for the work queue](#deploy-the-redis-server-which-we-use-for-the-work-queue)
    - [Adding sites to be crawled to the queue](#adding-sites-to-be-crawled-to-the-queue)
  - [Starting the crawl](#starting-the-crawl)
  - [Monitor Job](#monitor-job)
    - [Queue status](#queue-status)
    - [Job status](#job-status)
    - [View Job logs](#view-job-logs)
  - [Inspecting crawl results](#inspecting-crawl-results)
  - [Clean up all created containers](#clean-up-all-created-containers)
## Prerequisites

Install Docker and Docker Compose. Note that
Docker for Mac & Windows include Docker Compose


For the remainder of these instructions, you are assumed to be in the `deployment/local-compose/` folder.

### Build Docker image

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
### Set up a mock S3 service

```
docker-compose up -d localstack
```

### Deploy the redis server which we use for the work queue

```
docker-compose up -d redis
```

### Adding sites to be crawled to the queue

First set the REDIS_CONTAINER enviroment variable:
```
export REDIS_CONTAINER=$(docker-compose ps -q redis)
```
Create a comma-separated site list as per:

```
echo "1,http://www.example.com
2,http://www.example.org
3,http://www.princeton.edu
4,http://citp.princeton.edu/" > site_list.csv

../load_site_list_into_redis.sh crawl-queue site_list.csv 
```
This command will fail but leave you with a `joblist.txt` in your working directory.
Now copy the jobs into the redis container and load them into the redis queue.

```
docker cp joblist.txt $REDIS_CONTAINER:/tmp/joblist.txt 
docker exec $REDIS_CONTAINER sh -c "cat /tmp/joblist.txt | redis-cli --pipe"  
```

> All of the following commands will also fail leaving you to do the copying and
loading by yourself. The joblist file will be created in a one directory up,
so adjust the `docker cp` accordingly.

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

## Starting the crawl
Assuming you have setup the redis-queue all that is left to do is
```
docker-compose up -d crawler
```
Don't add the `-d` if you want to be attached to the stdout of the crawler
## Monitor Job

### Queue status

Get a redis-cli on the redis container:
```
docker exec -it $(docker-compose ps -q redis) sh -c "redis-cli "
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

### Job status

```
docker-compose ps
```

### View Job logs

To watch all output from all running containers continuously 
```
docker-compose logs -f
```

## Inspecting crawl results

When it has completed, run:
```
export LOCALSTACK_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker-compose ps -q localstack))

s3cmd --verbose --access_key=foo --secret_key=foo --host=http://$LOCALSTACK_IP:4572 --host-bucket=localhost --no-ssl sync s3://openwpm-crawls/local-crawl/ crawl-data/
```

The crawl data will end up in Parquet format in `./local-crawl-results/data`

## Clean up all created containers
```
docker-compose down
```
