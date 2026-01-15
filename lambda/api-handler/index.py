"""
API Handler Lambda Function
Handles API Gateway requests and processes events
"""

import json
import os
import boto3
import time
from datetime import datetime
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

# Patch boto3 for X-Ray tracing
patch_all()

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

# Environment variables
TABLE_NAME = os.environ.get('DYNAMODB_TABLE')
QUEUE_URL = os.environ.get('SQS_QUEUE_URL')

def handler(event, context):
    """
    API Gateway handler function
    """
    try:
        # Parse request
        http_method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
        path = event.get('rawPath', '/')
        
        if http_method == 'POST' and path == '/api/events':
            return create_event(event)
        elif http_method == 'GET' and path == '/api/events':
            return get_events(event)
        else:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Not found'})
            }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def create_event(event):
    """Create a new event"""
    try:
        body = json.loads(event.get('body', '{}'))
        event_id = f"evt_{int(time.time() * 1000)}"
        
        # Store in DynamoDB
        table = dynamodb.Table(TABLE_NAME)
        item = {
            'id': event_id,
            'type': body.get('type', 'default'),
            'data': body.get('data', {}),
            'timestamp': int(time.time()),
            'status': 'pending'
        }
        table.put_item(Item=item)
        
        # Send to SQS for async processing
        sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps({
                'event_id': event_id,
                'type': item['type'],
                'data': item['data']
            })
        )
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'id': event_id,
                'message': 'Event created successfully',
                'timestamp': datetime.utcnow().isoformat()
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }

def get_events(event):
    """Get events"""
    try:
        table = dynamodb.Table(TABLE_NAME)
        
        # Query events
        response = table.scan(
            Limit=100
        )
        
        events = response.get('Items', [])
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'events': events,
                'count': len(events)
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }
