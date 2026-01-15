"""
Notification Lambda Function
Sends notifications via SNS
"""

import json
import os
import boto3
import time
from aws_xray_sdk.core import patch_all

patch_all()

sns = boto3.client('sns')
TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def handler(event, context):
    """Send notification"""
    try:
        message = event.get('message', 'Default notification')
        subject = event.get('subject', 'Notification')
        
        # Publish to SNS
        response = sns.publish(
            TopicArn=TOPIC_ARN,
            Message=json.dumps({
                'default': message,
                'subject': subject,
                'timestamp': int(time.time())
            }),
            Subject=subject,
            MessageStructure='json'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'success': True,
                'message_id': response['MessageId']
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
