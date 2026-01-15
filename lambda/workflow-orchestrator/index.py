"""
Workflow Orchestrator Lambda Function
Orchestrates multi-step workflows
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
    """Orchestrate workflow"""
    try:
        workflow_id = event.get('workflow_id', f"wf_{int(time.time() * 1000)}")
        steps = event.get('steps', [])
        
        results = []
        
        for step in steps:
            step_name = step.get('name')
            step_data = step.get('data', {})
            
            # Process step
            result = {
                'step': step_name,
                'status': 'completed',
                'timestamp': int(time.time())
            }
            
            results.append(result)
        
        # Store workflow result
        table = dynamodb.Table(TABLE_NAME)
        table.put_item(
            Item={
                'id': workflow_id,
                'type': 'workflow',
                'data': {
                    'steps': results,
                    'status': 'completed'
                },
                'timestamp': int(time.time())
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'workflow_id': workflow_id,
                'steps': results,
                'status': 'completed'
            })
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
