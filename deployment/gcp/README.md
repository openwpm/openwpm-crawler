# Run a crawl in Google Cloud Platform

Documentation and scripts to launch an OpenWPM crawl on a Kubernetes cluster on GCP GKE.

## Prerequisites

- Access to GCP and the ability to provision resources in a GCP project
- [Google SDK](https://cloud.google.com/sdk/) installed locally
    - This will allow us to provision resources from CLI
- [Docker](https://hub.docker.com/search/?type=edition&offering=community)
    - We will use this to build the OpenWPM docker container
- A GCP Project setup, referred to below as `$PROJECT`
- Visit [GCP Kubernetes Engine API](https://console.cloud.google.com/apis/api/container.googleapis.com/overview) to enable the API.
    - You may need to set the Billing account.

For the remainder of these instructions, you are assumed to be in the `deployment/gcp/` folder

## Provision GCP Resources

### Configure the GCP Project

- `gcloud config set project $PROJECT` to the project that was created.
- `gcloud config set compute/zone us-central1-f` to the default region you want resources to be provisioned.
    - [GCP Regions](https://cloud.google.com/compute/docs/regions-zones/) for current list of regions.
- `gcloud components install kubectl`

### Setup GKE Cluster

The following command will create a zonal GKE cluster with [preemptible](https://cloud.google.com/preemptible-vms/) nodes. You may want to adjust fields within `./start_gke_cluster.sh` where appropriate such as:
- num-nodes, min-nodes, max-nodes
- [machine-type](https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform)
- See the [GKE Quickstart](https://cloud.google.com/kubernetes-engine/docs/quickstart) guide and [cluster create](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create) documentation.

```
./start_gke_cluster.sh crawl1
```

### Fetch kubernetes cluster credentials for use with `kubectl`

```
gcloud container clusters get-credentials crawl1
```

This allows subsequent `kubectl` commands to interact with our cluster.

## Build Docker image

Make sure that you have an up to date docker image of OpenWPM with openwpm-crawler support:

```
cd ../../OpenWPM; docker build -t openwpm .; cd -
```

## Push the Docker image to GCR

This makes it accessible to the cluster.

```
gcloud docker -- push gcr.io/$PROJECT/openwpm`
```

## Allow the cluster to access AWS S3

Make sure that your AWS credentials are stored in `~/.aws/credentials`, then run:

```
./aws_credentials_as_kubectl_secrets.sh
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
    - spec.containers.resources

When you are ready, deploy the crawl:

```
kubectl create -f crawl.yaml
```

Note that for the remainder of these instructions, `metadata.name` is assumed to be set to `openwpm-crawl`.

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
watch kubectl get pods --selector=job-name=openwpm-crawl
```

(Optional) To see a more detailed summary of the job as it executes or after it has finished:

```
kubectl describe job openwpm-crawl
```

Also, check out the [GCP GKE Console](https://console.cloud.google.com/kubernetes/workload)

#### View Job logs

```
mkdir -p openwpm-crawl-results/logs
for POD in $(kubectl get pods --selector=job-name=openwpm-crawl | grep -v NAME | grep -v Terminating | awk '{ print $1 }')
do
    kubectl logs $POD > openwpm-crawl-results/logs/$POD.log
done
```

The crawl logs will end up in `./openwpm-crawl-results/logs`

#### View Job logs via GCP Stackdriver Logging Interface

- Visit [GCP Logging Console](https://console.cloud.google.com/logs/viewer)
- Select `GKE Container`

#### Using the Kubernetes Dashboard UI

(Optional) You can also spin up the Kubernetes Dashboard UI as per [these instructions](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#deploying-the-dashboard-ui) which will allow for easy access to status and logs related to running jobs/crawls.

### Inspecting crawl results

The crawl data will end up in Parquet format in the S3 bucket that you configured.

### Clean up created pods, services and local artifacts

```
kubectl delete -f redis.yaml
kubectl delete -f crawl.yaml
kubectl delete pod temp
rm -r openwpm-crawl-results/logs
```

### Deleting the GKE Cluster

```
gcloud container clusters delete crawl1
```
