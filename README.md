# OpenWPM Crawler 

Launch OpenWPM crawls using Kubernetes [Job](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/) workloads to run the crawl.

The OpenWPM crawler.py script will continuously fetch sites to run and exit once there are no additional sites in the queue.

## Preparations

```
./setup-python-venv.sh
```

## Run a crawl locally (using Kubernetes)

See [./deployment/local/README.md](./deployment/local/README.md).

## Run a crawl in Google Cloud Platform

See [./deployment/gcp/README.md](./deployment/gcp/README.md).

## Developer notes

To update the OpenWPM submodule to the latest commit in the remotely tracked branch:

```
git submodule update --remote OpenWPM
```
