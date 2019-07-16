# Run a local OpenWPM crawl using Kubernetes

Documentation and scripts to launch an OpenWPM crawl on a Kubernetes cluster locally.

## Prerequisites

Install Docker and Kubernetes locally. Note that [Docker for Mac](https://docs.docker.com/docker-for-mac/install/) includes [Kubernetes](https://docs.docker.com/docker-for-mac/#kubernetes).

For the remainder of these instructions, you are assumed to be in the `deployment/local/` folder.

## Build Docker image

Make sure that you have an up to date docker image of OpenWPM with openwpm-crawler support:

```
cd ../../OpenWPM; docker build -t openwpm .; cd -
```

## Set up a mock S3 service

```
kubectl apply -f localstack.yaml
```

## Deploy the redis server which we use for the work queue

```
kubectl apply -f redis.yaml
```

## Adding sites to be crawled to the queue

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
../load_alexa_top_1m_site_list_into_redis.sh crawl-queue site_list.csv 
```

(Optional) Use some of the `../../utilities/crawl_utils.py` code. For instance, to fetch and store a sample of Alexa Top 1M to `/tmp/sampled_sites.json`:
```
source ../../venv/bin/activate
cd ../../; python -m utilities.get_sampled_sites; cd -
```

## Deploying the crawl Job

Since each crawl is unique, you need to configure your `crawl.yaml` deployment configuration. We have provided a template to start from:
```
cp crawl.tmpl.yaml crawl.yaml
```

- Update `crawl.yaml`. This may include:
    - spec.parallelism
    - spec.containers.image
    - spec.containers.env

When you are ready, deploy the crawl:

```
kubectl create -f crawl.yaml
```

Note that for the remainder of these instructions, `metadata.name` is assumed to be set to `local-crawl`.

### Monitor Job

#### Queue status

Open a temporary instance and launch redis-cli:
```
kubectl attach temp -c temp -i -t || kubectl run --generator=run-pod/v1 -i --tty temp --image redis --command "/bin/bash"
redis-cli -h redis
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
```

#### Job status

```
watch kubectl get pods --selector=job-name=local-crawl
```

(Optional) To see a more detailed summary of the job as it executes or after it has finished:

```
kubectl describe job local-crawl
```

#### View Job logs

```
mkdir -p local-crawl-results/logs
for POD in $(kubectl get pods --selector=job-name=local-crawl | grep -v NAME | grep -v Terminating | awk '{ print $1 }')
do
    kubectl logs $POD > local-crawl-results/logs/$POD.log
done
```

The crawl logs will end up in `./local-crawl-results/logs`

#### Using the Kubernetes Dashboard UI

(Optional) You can also spin up the Kubernetes Dashboard UI as per [these instructions](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#deploying-the-dashboard-ui) which will allow for easy access to status and logs related to running jobs/crawls.

### Inspecting crawl results

```
s3cmd --verbose --access_key=foo --secret_key=foo --host=http://localhost:32001 --host-bucket=localhost --no-ssl sync --delete-removed s3://localstack-foo local-crawl-results/data
```

The crawl data will end up in Parquet format in `./local-crawl-results/data`

### Clean up created pods, services and local artifacts

```
mkdir /tmp/empty
s3cmd --verbose --access_key=foo --secret_key=foo --host=http://localhost:32001 --host-bucket=localhost --no-ssl sync --delete-removed --force /tmp/empty/ s3://localstack-foo
kubectl delete -f localstack.yaml
kubectl delete -f redis.yaml
kubectl delete -f crawl.yaml
kubectl delete pod temp
rm -r local-crawl-results/data
rm -r local-crawl-results/logs
```
