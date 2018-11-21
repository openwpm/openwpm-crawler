import datetime
import sys

import boto3

# Instance configuration
NUM_INSTANCES = 1
INSTANCE_TYPE = 'c4.2xlarge'
AMI_ID = 'ami-0ac019f4fcb7cb7e6'  # Ubuntu 18.04 LTS
KEY_NAME = 'senglehardt'
REGION = 'us-east-1'

# IAM role gives access to `openwpm-crawls` S3 bucket
IAM_ARN = 'arn:aws:iam::927034868273:instance-profile/openwpmCrawler'

# Instance name
NAME_PREFIX = 'openwpm-'
DATE_PREFIX = datetime.datetime.strftime(datetime.datetime.now(), '%Y-%m-%d')

STARTUP_SCRIPT_TEMPLATE = open('instance_startup.sh', 'r').read()

if len(sys.argv) != 4:
    print("Usage: python instance_creator.py "
          "[BRANCH_NAME] [CRAWL_SCRIPT] [CRAWL_NAME]")
    sys.exit(1)

branch_name = sys.argv[1]
crawl_script = sys.argv[2]
crawl_name = sys.argv[3]

startup_script = STARTUP_SCRIPT_TEMPLATE.format(
    branch_name,
    "%s_%s" % (DATE_PREFIX, crawl_name),
    crawl_script,
    crawl_script
)

ec2 = boto3.resource('ec2', region_name=REGION)
instance = ec2.create_instances(
    ImageId=AMI_ID,
    MinCount=NUM_INSTANCES,
    MaxCount=NUM_INSTANCES,
    KeyName=KEY_NAME,
    UserData=startup_script,
    InstanceType=INSTANCE_TYPE,
    IamInstanceProfile={
        'Arn': IAM_ARN,
    }
)[0]
instance.create_tags(
    Tags=[{
        'Key': 'Name',
        'Value': NAME_PREFIX + DATE_PREFIX + '-' + crawl_name
    }]
)
print("Crawl successfully started")
