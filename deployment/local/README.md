# Run a local OpenWPM crawl using Kubernetes

## Preparations

Install Docker and Kubernetes locally. Note that [Docker for Mac](https://docs.docker.com/docker-for-mac/install/) includes [Kubernetes](https://docs.docker.com/docker-for-mac/#kubernetes).

Then run:

```
cd ../../OpenWPM
docker build -t openwpm .
cd -
```

For the remainder of these instructions, you are assumed to be in the `deployment/local/` folder.

## Set up a mock S3 service and a local redis server which we use for the work queue

```
kubectl apply -f localstack.yaml
python -m utils.setup_local_s3_bucket
kubectl apply -f redis.yaml
```

## Adding sites to be crawled to the queue

```
python -m utils.load_site_list_into_redis
```

(Optional) To inspect the current queue:
```
kubectl delete pod temp
kubectl run --generator=run-pod/v1 -i --tty temp --image redis --command "/bin/bash"
redis-cli -h redis
lrange crawl-queue 0 -1
```

## Deploying the crawl Job

```
kubectl create -f crawl.yaml
```

### Monitor Job

```
watch kubectl get pods --selector=job-name=local-crawl
```

(Optional) To see a more detailed summary of the job as it executes or after it has finished:

```
kubectl describe job local-crawl
```

### View Job logs

```
mkdir -p local-crawl-results/logs
for POD in $(kubectl get pods --selector=job-name=local-crawl | grep -v NAME | awk '{ print $1 }')
do
    kubectl logs $POD > local-crawl-results/logs/$POD.log
done
```

The crawl logs will end up in `./local-crawl-results/logs`

### Inspecting crawl results

When it has completed, run:
```
python -m utils.download_files_from_local_s3
```

The crawl data will end up in Parquet format in `./local-crawl-results/data`

### Clean up created pods, services and local artifacts

```
kubectl delete -f localstack.yaml
kubectl delete -f redis.yaml
kubectl delete -f crawl.yaml
kubectl delete pod temp
rm -r local-crawl-results/data
rm -r local-crawl-results/logs
```
