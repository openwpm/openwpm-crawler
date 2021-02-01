#!/bin/bash
set -e

if [[ $# -lt 1 ]]; then
    echo "Usage: start_gke_cluster.sh cluster_name additional_args" >&2
    exit 1
fi
CLUSTER_NAME=$1
ADDITIONAL_ARGS="${*:2}"

gcloud container clusters create $CLUSTER_NAME \
--zone us-central1-f \
--enable-stackdriver-kubernetes \
--labels='app=openwpm' \
--machine-type=n1-highcpu-16 \
--num-nodes=1 \
--min-nodes=0 \
--max-nodes=30 \
--enable-autoscaling \
--enable-ip-alias \
--scopes storage-rw \
--min-cpu-platform="Intel Broadwell" $ADDITIONAL_ARGS
