from __future__ import absolute_import
import boto3
from OpenWPM.test.utilities import LocalS3Session, local_s3_bucket


def use_local_s3_service(endpoint_url='http://localhost:32001'):
    boto3.DEFAULT_SESSION = LocalS3Session(endpoint_url=endpoint_url)
    s3_client = boto3.client('s3')
    s3_resource = boto3.resource('s3')
    s3_bucket = local_s3_bucket(s3_resource)
    return s3_client, s3_resource, s3_bucket
