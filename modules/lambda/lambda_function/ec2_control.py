import json
import boto3

ec2 = boto3.client('ec2')
dynamodb = boto3.resource('dynamodb')
token_table = dynamodb.Table('TokenStore')

def get_instances_by_tag(tag_key, tag_value):
    """Retrieve instance IDs for EC2 instances matching the given tag, excluding terminated/terminating."""
    response = ec2.describe_instances(Filters=[
        {'Name': f'tag:{tag_key}', 'Values': [tag_value]},
        {'Name': 'instance-state-name', 'Values': ['running', 'stopped', 'pending', 'stopping']}
    ])
    instances = [i['InstanceId'] for r in response['Reservations'] for i in r['Instances']]
    return instances

def get_instances_state(instance_ids):
    """Check power state of instances and return state or 'mix' if varied."""
    response = ec2.describe_instances(InstanceIds=instance_ids)
    states = {i['State']['Name'] for r in response['Reservations'] for i in r['Instances']
              if i['State']['Name'] in ['running', 'stopped', 'pending', 'stopping']}
    
    return states.pop() if len(states) == 1 else 'mix'

def get_token_count(token_id):
    """Get token count from DynamoDB, create with 0 if not exists."""
    try:
        response = token_table.get_item(Key={'id': token_id})
        if 'Item' in response:
            return int(response['Item']['token'])
        else:
            # Create new record with token count 0
            token_table.put_item(Item={'id': token_id, 'token': 0})
            return 0
    except Exception as e:
        raise Exception(f"Error getting token count: {str(e)}")

def set_token_count(token_id, count):
    """Set token count in DynamoDB."""
    try:
        token_table.put_item(Item={'id': token_id, 'token': count})
        return count
    except Exception as e:
        raise Exception(f"Error setting token count: {str(e)}")

def subtract_token(token_id):
    """Subtract one from token count, return new count."""
    try:
        response = token_table.update_item(
            Key={'id': token_id},
            UpdateExpression='SET #t = if_not_exists(#t, :zero) - :one',
            ExpressionAttributeNames={'#t': 'token'},
            ExpressionAttributeValues={':one': 1, ':zero': 0},
            ReturnValues='UPDATED_NEW'
        )
        return int(response['Attributes']['token'])
    except Exception as e:
        raise Exception(f"Error subtracting token: {str(e)}")

def lambda_handler(event, context):
    try:
        resource = event.get('resource', '')
        http_method = event.get('httpMethod', 'POST')

        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,x-api-key',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        }

        # Handle token operations
        if resource.startswith('/tokens'):
            # Get token_id from queryStringParameters for GET, body for POST
            token_id = None
            if http_method == 'GET' and event.get('queryStringParameters'):
                token_id = event['queryStringParameters'].get('id', 'default-token')
            elif http_method == 'POST':
                body = json.loads(event.get('body', '{}'))
                token_id = body.get('id', 'default-token')

            if not token_id:
                return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': 'Missing token id'})}

            if resource.endswith('/count') and http_method == 'GET':
                count = get_token_count(token_id)
                return {'statusCode': 200, 'headers': headers, 'body': json.dumps({'count': count})}
            
            elif resource.endswith('/count') and http_method == 'POST':
                body = json.loads(event.get('body', '{}'))
                action = body.get('action')
                if action == 'set':
                    count = body.get('count')
                    if not isinstance(count, int) or count < 0:
                        return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': 'Count must be a non-negative integer'})}
                    new_count = set_token_count(token_id, count)
                    return {'statusCode': 200, 'headers': headers, 'body': json.dumps({'count': new_count})}
                
                elif action == 'subtract':
                    new_count = subtract_token(token_id)
                    return {'statusCode': 200, 'headers': headers, 'body': json.dumps({'count': new_count})}
                
                else:
                    return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': 'Invalid action. Use "set" or "subtract".'})}

        # EC2 operations
        instance_ids = get_instances_by_tag('environment', 'ut')
        if not instance_ids:
            return {'statusCode': 404, 'headers': headers, 'body': json.dumps({'error': 'No active instances found'})}

        if resource.endswith('/state') or http_method == 'GET':
            state = get_instances_state(instance_ids)
            return {'statusCode': 200, 'headers': headers, 'body': json.dumps({'state': state})}
        
        elif http_method == 'POST':
            body = json.loads(event['body'])
            action = body.get('action')
            if action not in ['start', 'stop']:
                return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': 'Invalid action. Use "start" or "stop".'})}

            if action == 'start':
                ec2.start_instances(InstanceIds=instance_ids)
                message = f'Instances {instance_ids} starting'
            else:
                ec2.stop_instances(InstanceIds=instance_ids)
                message = f'Instances {instance_ids} stopping'

            return {'statusCode': 200, 'headers': headers, 'body': json.dumps({'message': message})}
        
        else:
            return {'statusCode': 400, 'headers': headers, 'body': json.dumps({'error': 'Unsupported HTTP method or resource'})}

    except Exception as e:
        return {'statusCode': 500, 'headers': headers, 'body': json.dumps({'error': str(e)})}