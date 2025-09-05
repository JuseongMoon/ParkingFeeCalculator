# parking_session_handler.py
import json
import boto3
import uuid
from datetime import datetime, timedelta
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
sessions_table = dynamodb.Table('ParkingSessions')
eventbridge = boto3.client('scheduler')

def lambda_handler(event, context):
    """
    주차 세션 시작/종료 및 Push Token 업데이트 처리
    """
    try:
        http_method = event.get('httpMethod', '')
        path = event.get('path', '')
        
        if path == '/sessions/start' and http_method == 'POST':
            return start_session(json.loads(event['body']))
        
        elif path.endswith('/end') and http_method == 'POST':
            session_id = path.split('/')[-2]
            return end_session(session_id)
        
        elif path.endswith('/push-token') and http_method == 'PUT':
            session_id = path.split('/')[-2]
            return update_push_token(session_id, json.loads(event['body']))
        
        return {
            'statusCode': 404,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Not found'})
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Internal server error'})
        }


def start_session(request_body):
    """
    새 주차 세션 시작 및 첫 업데이트 스케줄링
    """
    session_id = request_body['sessionId']
    start_time = request_body['startTime']
    
    # 할인율 계산
    discount_rate = calculate_discount_rate(request_body)
    
    # 세션 데이터 저장 (최소 필드만)
    session_data = {
        'sessionId': session_id,
        'startTime': start_time,
        'parkingLotName': request_body['parkingLotName'][:20],  # 20자 제한
        'feeConfig': {
            'freeMinutes': int(request_body['feeCalculatorConfig']['freeMinutes']),
            'initialMinutes': int(request_body['feeCalculatorConfig']['initialMinutes']),
            'initialFee': int(request_body['feeCalculatorConfig']['initialFee']),
            'additionalMinutes': int(request_body['feeCalculatorConfig']['additionalMinutes']),
            'additionalFee': int(request_body['feeCalculatorConfig']['additionalFee']),
            'maxFee': request_body['feeCalculatorConfig'].get('maxFee')
        },
        'additionalFreeMinutes': int(request_body.get('additionalFreeMinutes', 0)),
        'discountRate': discount_rate,  # 할인율만 저장
        'status': 'active',
        'createdAt': datetime.now().isoformat(),
        'ttl': int((datetime.now() + timedelta(hours=9)).timestamp())  # 9시간 후 자동 삭제
    }
    
    # DynamoDB에 저장
    sessions_table.put_item(Item=session_data)
    
    # 다음 요금 변경 시간 계산
    next_change_time = calculate_next_change_time(start_time, session_data)
    
    # EventBridge 스케줄 생성 (다음 요금 변경 시점)
    schedule_id = None
    if next_change_time:
        schedule_id = schedule_next_update(session_id, next_change_time)
    
    print(f"✅ Session started: {session_id}, Next update: {next_change_time}")
    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({
            'sessionId': session_id,
            'status': 'started',
            'nextUpdate': next_change_time.isoformat() if next_change_time else None,
            'scheduleId': schedule_id
        })
    }


def end_session(session_id):
    """
    주차 세션 종료 및 스케줄 삭제
    """
    # 세션 상태 업데이트
    sessions_table.update_item(
        Key={'sessionId': session_id},
        UpdateExpression='SET #status = :status, endTime = :endTime',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={
            ':status': 'ended',
            ':endTime': datetime.now().isoformat()
        }
    )
    
    # EventBridge 스케줄 삭제
    try:
        schedule_name = f'parking-{session_id}'
        eventbridge.delete_schedule(Name=schedule_name)
        print(f"🗑️ Schedule deleted: {schedule_name}")
    except Exception as e:
        print(f"⚠️ Schedule deletion failed (might not exist): {str(e)}")
    
    print(f"🛑 Session ended: {session_id}")
    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({'status': 'ended'})
    }


def update_push_token(session_id, body):
    """
    Push Token 업데이트 (세션에 저장)
    """
    try:
        sessions_table.update_item(
            Key={'sessionId': session_id},
            UpdateExpression='SET pushToken = :token, activityId = :activity, tokenUpdatedAt = :updatedAt',
            ExpressionAttributeValues={
                ':token': body['pushToken'],
                ':activity': body['activityId'],
                ':updatedAt': datetime.now().isoformat()
            }
        )
        
        print(f"🔑 Push token updated for session: {session_id}")
        
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'status': 'updated'})
        }
        
    except Exception as e:
        print(f"❌ Push token update failed: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Token update failed'})
        }


def calculate_discount_rate(request_body):
    """
    할인율 계산 (단순화: 최대 할인율만 반환)
    """
    discount = 0
    
    try:
        # 차량 할인
        vehicle = request_body.get('vehicleProfile', {})
        if vehicle.get('isElectric'):
            discount = max(discount, 50)
        if vehicle.get('isCompact'):
            discount = max(discount, 50)
        
        # 운전자 할인
        driver = request_body.get('driverProfile', {})
        if driver.get('hasDisabilityDiscount'):
            discount = max(discount, 80)
        if driver.get('hasSeniorDiscount'):
            discount = max(discount, 80)
        if driver.get('hasLowIncomeDiscount'):
            discount = max(discount, 50)
        if driver.get('hasMultiChildDiscount'):
            discount = max(discount, 50)
        if driver.get('hasNationalMeritDiscount'):
            discount = max(discount, 30)
            
    except Exception as e:
        print(f"⚠️ Discount calculation warning: {str(e)}")
        discount = 0
    
    return discount


def calculate_next_change_time(start_time_str, session_data):
    """
    다음 요금 변경 시점 계산
    """
    try:
        # ISO 형식 파싱
        if start_time_str.endswith('Z'):
            start_time_str = start_time_str[:-1] + '+00:00'
        start_time = datetime.fromisoformat(start_time_str)
        
        fee_config = session_data['feeConfig']
        additional_free = session_data.get('additionalFreeMinutes', 0)
        
        total_free_minutes = fee_config['freeMinutes'] + additional_free
        
        # 무료 시간이 있으면 무료 시간 종료 시점
        if total_free_minutes > 0:
            return start_time + timedelta(minutes=total_free_minutes)
        
        # 무료 시간이 없으면 초기 요금 시간 종료 시점
        return start_time + timedelta(minutes=fee_config['initialMinutes'])
        
    except Exception as e:
        print(f"❌ Next change time calculation failed: {str(e)}")
        return None


def schedule_next_update(session_id, next_time):
    """
    EventBridge 일회성 스케줄 생성
    """
    try:
        # UTC 시간으로 변환
        if next_time.tzinfo is None:
            next_time = next_time.replace(tzinfo=datetime.now().astimezone().tzinfo)
        
        schedule_name = f'parking-{session_id}'
        
        # Lambda 함수 ARN (환경변수에서 가져오기)
        import os
        push_sender_arn = os.environ.get('PUSH_SENDER_LAMBDA_ARN')
        eventbridge_role_arn = os.environ.get('EVENTBRIDGE_ROLE_ARN')
        
        if not push_sender_arn or not eventbridge_role_arn:
            print("❌ Missing environment variables for scheduling")
            return None
        
        eventbridge.create_schedule(
            Name=schedule_name,
            ScheduleExpression=f'at({next_time.strftime("%Y-%m-%dT%H:%M:%S")})',
            Target={
                'Arn': push_sender_arn,
                'RoleArn': eventbridge_role_arn,
                'Input': json.dumps({'sessionId': session_id})
            },
            FlexibleTimeWindow={'Mode': 'OFF'},
            ActionAfterCompletion='DELETE'  # 실행 후 자동 삭제
        )
        
        print(f"⏰ Schedule created: {schedule_name} at {next_time}")
        return schedule_name
        
    except Exception as e:
        print(f"❌ Schedule creation failed: {str(e)}")
        return None