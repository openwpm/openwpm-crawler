from __future__ import absolute_import
import os
import boto3
from utils.use_local_s3_service import use_local_s3_service


def download_s3_directory(dir, destination='/tmp', bucket='your_bucket'):
    client = boto3.client('s3')
    resource = boto3.resource('s3')
    paginator = client.get_paginator('list_objects')
    for result in paginator.paginate(Bucket=bucket, Delimiter='/', Prefix=dir):
        if result.get('CommonPrefixes') is not None:
            for subdir in result.get('CommonPrefixes'):
                download_s3_directory(
                    subdir.get('Prefix'), destination, bucket)
        for file in result.get('Contents', []):
            dest_pathname = os.path.join(destination, file.get('Key'))
            if not os.path.exists(os.path.dirname(dest_pathname)):
                os.makedirs(os.path.dirname(dest_pathname))
            resource.meta.client.download_file(
                bucket, file.get('Key'), dest_pathname)


def copy_crawl_results_from_local_s3_service_to_local_directory(s3_bucket, s3_directory):
    print("Copying the resulting S3 contents...")
    destination = os.path.join(os.path.dirname(__file__), '..', 'local-crawl-results', 'data')
    download_s3_directory(
        s3_directory,
        destination,
        s3_bucket)
    print("Copied the resulting S3 contents to " + destination + "/" + s3_directory)


s3_client, s3_resource, s3_bucket = use_local_s3_service()
s3_directory = 'openwpm-crawl'
copy_crawl_results_from_local_s3_service_to_local_directory(s3_bucket, s3_directory)
