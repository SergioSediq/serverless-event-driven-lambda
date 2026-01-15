"""
Data Transformer Lambda Function
Transforms and processes data
"""

import json
import os
import boto3
import time
from aws_xray_sdk.core import patch_all

patch_all()

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE')

def handler(event, context):
    """Transform data"""
    try:
        # Get data from event
        data = event.get('data', {})
        
        # Transform data
        transformed = {
            'original': data,
            'transformed': {
                'uppercase_keys': {k.upper(): str(v).upper() for k, v in data.items()},
                'timestamp': int(time.time())
            }
        }
        
        # Store transformed data
        table = dynamodb.Table(TABLE_NAME)
        table.put_item(
            Item={
                'id': f"trans_{int(time.time() * 1000)}",
                'type': 'transformed',
                'data': transformed,
                'timestamp': int(time.time())
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'success': True,
                'transformed': transformed
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
