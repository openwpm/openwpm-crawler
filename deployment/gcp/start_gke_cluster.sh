#!/bin/bash
set -e

CLUSTER_NAME=crawl1

gcloud container clusters create $CLUSTER_NAME \
--zone us-central1-f \
--enable-cloud-logging \
--enable-cloud-monitoring \
--labels='app=openwpm' \
--machine-type=n1-highcpu-16 \
--num-nodes=5 \
--min-nodes=0 \
--max-nodes=30 \
--enable-autoscaling \
--min-cpu-platform="Intel Broadwell" \
--preemptible

gcloud container clusters get-credentials $CLUSTER_NAME
