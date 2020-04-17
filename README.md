# OpenWPM Crawler 

Launch OpenWPM crawls using Kubernetes [Job](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/) workloads
or stand up some docker-compose services to run the crawl in a distributed fashion.

A Redis work queue is set up and loaded with the list of URLs to crawl.

Containers running either locally
or in the cloud execute the OpenWPM crawler.py script which will continuously fetch sites to run
and exit once there are no additional sites in the queue.

## Preparations

```
./setup-python-venv.sh
```

Due to a bug with `plyvel` and recent versions of Mac OSX, use the following if you are on a Mac:

```
./setup-python-venv-mac.sh
```

## Run a crawl locally (using Kubernetes)

See [./deployment/local/README.md](./deployment/local/README.md).

## Run a crawl in Google Cloud Platform

See [./deployment/gcp/README.md](./deployment/gcp/README.md).

## Run a crawl locally (using docker-compose)

See [./deployment/local-compose/README.md](./deployment/local-compose/README.md).
This is the simplest option, requiring only docker-compose which is shipped with
Docker on both Mac and Windows, however behaviour might slightly differ from
cloud crawls.

## Analyze crawl results

```
jupyter notebook
```

After launching Jupyter, navigate to `analysis/Sample Analysis.ipynb` and choose `Kernel -> Change Kernel -> openwpm-crawler` in the menu.
