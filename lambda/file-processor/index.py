"""
File Processor Lambda Function
Processes files uploaded to S3
"""

import json
import os
import boto3
import time
from aws_xray_sdk.core import patch_all

patch_all()

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE')
BUCKET_NAME = os.environ.get('S3_BUCKET')

def handler(event, context):
    """Process S3 file upload"""
    try:
        records = event.get('Records', [])
        processed = 0
        
        for record in records:
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
            
            # Get file metadata
            response = s3.head_object(Bucket=bucket, Key=key)
            file_size = response['ContentLength']
            content_type = response.get('ContentType', 'unknown')
            
            # Store file info in DynamoDB
            table = dynamodb.Table(TABLE_NAME)
            table.put_item(
                Item={
                    'id': f"file_{int(time.time() * 1000)}",
                    'type': 'file_processed',
                    'data': {
                        'bucket': bucket,
                        'key': key,
                        'size': file_size,
                        'content_type': content_type
                    },
                    'timestamp': int(time.time())
                }
            )
            
            processed += 1
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'processed': processed,
                'total': len(records)
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
