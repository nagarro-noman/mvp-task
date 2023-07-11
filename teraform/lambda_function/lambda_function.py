import boto3
import logging

s3 = boto3.client('s3')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    print("bucket " + bucket)
    print("key " + key)
    
    response = s3.get_object(Bucket=bucket, Key=key)
    content = response['Body'].read().decode('utf-8')
    char_count = len(content)

    logger.info(f"Uploaded file '{key}' in bucket '{bucket}' has {char_count} characters.")
