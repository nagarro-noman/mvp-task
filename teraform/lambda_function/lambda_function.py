import boto3
import logging
import pymysql
from botocore.exceptions import ClientError

s3 = boto3.client('s3')
ssm = boto3.client('ssm')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_rds_endpoint():
    try:
        response = ssm.get_parameter(Name='/rds/endpoint', WithDecryption=False)
        rds_endpoint = response['Parameter']['Value']
        return rds_endpoint
    except ClientError as e:
        logger.error(f"Error retrieving RDS endpoint from Parameter Store: {str(e)}")
        raise e

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    response = s3.get_object(Bucket=bucket, Key=key)
    content = response['Body'].read().decode('utf-8')
    char_count = len(content)

    logger.info(f"Uploaded file '{key}' in bucket '{bucket}' has {char_count} characters.")
    
    response = s3.delete_object(Bucket=bucket, Key=key)

    # Store data in RDS
    rds_host = get_rds_endpoint()
    db_name = "mydatabase"
    username = "admin"
    password = "password"

    try:
        conn = pymysql.connect(rds_host, user=username, passwd=password, db=db_name, connect_timeout=5)
        with conn.cursor() as cursor:
            insert_query = "INSERT INTO character_counts (name, letter_count) VALUES (%s, %s)"
            cursor.execute(insert_query, (key, char_count))
            conn.commit()
        logger.info("Data stored in RDS successfully.")
    except Exception as e:
        logger.error(f"Error storing data in RDS: {str(e)}")
