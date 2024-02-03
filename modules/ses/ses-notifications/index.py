import json
import os
import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import BotoCoreError, ClientError
from typing import Dict, Any
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SES_TABLE_NAME = os.environ['SES_TABLE_NAME']

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(SES_TABLE_NAME)

def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    logger.info(f"Received event: {json.dumps(event)}")
    return