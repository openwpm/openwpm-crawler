#!/bin/bash
set -e

AWS_CREDENTIALS_FILE=~/.aws/credentials

if kubectl get secret | grep -q 'aws-config'; then
  echo Secret aws-config already created. Overwriting...
  kubectl delete secret aws-config
fi

aws_access_key_id=$(awk -F "\\\\s*=\\\\s*" '/aws_access_key_id/{print $2}' $AWS_CREDENTIALS_FILE | xargs echo)
aws_secret_access_key=$(awk -F "\\\\s*=\\\\s*" '/aws_secret_access_key/{print $2}' $AWS_CREDENTIALS_FILE | xargs echo)
kubectl create secret generic aws-config \
--from-literal=aws_access_key_id=$aws_access_key_id \
--from-literal=aws_secret_access_key=$aws_secret_access_key
