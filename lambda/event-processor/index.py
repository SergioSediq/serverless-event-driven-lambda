"""
Event Processor Lambda Function
Processes events from SQS queue
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
    """Process SQS messages"""
    records = event.get('Records', [])
    processed = 0
    
    for record in records:
        try:
            # Parse SQS message
            body = json.loads(record['body'])
            event_id = body.get('event_id')
            
            # Update event status
            table = dynamodb.Table(TABLE_NAME)
            table.update_item(
                Key={'id': event_id},
                UpdateExpression='SET #status = :status, processed_at = :processed_at',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'processed',
                    ':processed_at': int(time.time())
                }
            )
            
            processed += 1
        
        except Exception as e:
            print(f"Error processing record: {str(e)}")
            raise
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'processed': processed,
            'total': len(records)
        })
    }
