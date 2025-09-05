# parking_push_sender.py
import json
import boto3
import jwt
import time
import requests
import os
from datetime import datetime, timedelta

dynamodb = boto3.resource('dynamodb')
sessions_table = dynamodb.Table('ParkingSessions')
eventbridge = boto3.client('scheduler')

# APNs 설정 (환경 변수에서 로드)
APNS_KEY_ID = os.environ.get('APNS_KEY_ID')
APNS_TEAM_ID = os.environ.get('APNS_TEAM_ID')
APNS_BUNDLE_ID = os.environ.get('APNS_BUNDLE_ID')
APNS_KEY = os.environ.get('APNS_PRIVATE_KEY')  # PEM 형식 전체 키
APNS_ENVIRONMENT = os.environ.get('APNS_ENVIRONMENT', 'production')  # 'sandbox' or 'production'

def lambda_handler(event, context):
    """
    주차 요금 계산 후 APNs Push 전송
    """
    try:
        session_id = event['sessionId']
        print(f"🚀 Processing session: {session_id}")
        
        # 세션 정보 조회
        response = sessions_table.get_item(Key={'sessionId': session_id})
        if 'Item' not in response:
            print(f"❌ Session not found: {session_id}")
            return {'statusCode': 404, 'body': 'Session not found'}
        
        session = response['Item']
        
        # 세션이 종료되었으면 처리 안 함
        if session.get('status') != 'active':
            print(f"ℹ️ Session not active: {session_id} (status: {session.get('status')})")
            return {'statusCode': 200, 'body': 'Session not active'}
        
        # 현재 요금 계산
        current_fee = calculate_current_fee(session)
        
        # Push 페이로드 생성 (4KB 제한 준수)
        payload = create_push_payload(session, current_fee)
        
        # APNs로 Push 전송
        push_success = False
        if session.get('pushToken'):
            push_success = send_push(
                session['pushToken'],
                session.get('activityId', session_id),
                payload
            )
        else:
            print(f"⚠️ No push token for session: {session_id}")
        
        # 다음 업데이트 시간 계산 및 스케줄링
        next_change_time = calculate_next_update(session)
        if next_change_time:
            schedule_next_update(session_id, next_change_time)
        else:
            print(f"🏁 No more updates needed for session: {session_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'sessionId': session_id,
                'fee': current_fee,
                'pushSent': push_success,
                'nextUpdate': next_change_time.isoformat() if next_change_time else None
            })
        }
        
    except Exception as e:
        print(f"❌ Error processing session {event.get('sessionId', 'unknown')}: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}


def calculate_current_fee(session):
    """
    현재 시점 주차 요금 계산 (심플 버전)
    """
    try:
        start_time_str = session['startTime']
        if start_time_str.endswith('Z'):
            start_time_str = start_time_str[:-1] + '+00:00'
        start_time = datetime.fromisoformat(start_time_str)
        
        now = datetime.now(start_time.tzinfo) if start_time.tzinfo else datetime.now()
        elapsed_seconds = (now - start_time).total_seconds()
        elapsed_minutes = int(elapsed_seconds / 60)
        
        config = session['feeConfig']
        additional_free = session.get('additionalFreeMinutes', 0)
        total_free_minutes = config['freeMinutes'] + additional_free
        
        print(f"💰 Fee calculation - Elapsed: {elapsed_minutes}min, Free: {total_free_minutes}min")
        
        # 무료 시간
        if elapsed_minutes <= total_free_minutes:
            return 0
        
        # 과금 대상 시간 계산
        billable_minutes = elapsed_minutes - total_free_minutes
        
        # 초기 요금 구간
        if billable_minutes <= config['initialMinutes']:
            fee = config['initialFee']
        else:
            # 추가 요금 계산
            extra_minutes = billable_minutes - config['initialMinutes']
            # 올림 계산 (예: 31분이면 2구간으로 계산)
            extra_units = (extra_minutes + config['additionalMinutes'] - 1) // config['additionalMinutes']
            fee = config['initialFee'] + (extra_units * config['additionalFee'])
        
        # 최대 요금 제한
        if config.get('maxFee') and fee > config['maxFee']:
            fee = config['maxFee']
        
        # 할인 적용
        discount_rate = session.get('discountRate', 0)
        if discount_rate > 0:
            original_fee = fee
            fee = int(fee * (100 - discount_rate) / 100)
            print(f"💸 Discount applied: {original_fee} -> {fee} ({discount_rate}% off)")
        
        print(f"💰 Calculated fee: {fee}원")
        return fee
        
    except Exception as e:
        print(f"❌ Fee calculation error: {str(e)}")
        return 0


def create_push_payload(session, current_fee):
    """
    APNs Push 페이로드 생성 (최소 크기, 4KB 제한 준수)
    """
    try:
        # 할인 정보 (있을 때만, 짧게)
        discount_info = None
        discount_rate = session.get('discountRate', 0)
        if discount_rate > 0:
            discount_info = f"{discount_rate}%할인"
        
        # 다음 변경 시점
        next_change = calculate_next_update(session)
        
        # 최소 필수 필드만 포함
        payload = {
            'aps': {
                'timestamp': int(time.time()),
                'event': 'update',
                'content-state': {
                    'startTime': session['startTime'],
                    'lotName': session['parkingLotName'][:20],  # 길이 제한
                    'fee': current_fee,
                    'discount': discount_info[:10] if discount_info else None,  # 10자 제한
                    'nextChange': next_change.isoformat() if next_change else None
                }
            }
        }
        
        # 페이로드 크기 체크
        payload_size = len(json.dumps(payload, ensure_ascii=False).encode('utf-8'))
        print(f"📦 Payload size: {payload_size} bytes")
        
        if payload_size > 4096:
            print(f"⚠️ Payload too large ({payload_size} bytes), truncating...")
            # 긴급 축소
            payload['aps']['content-state']['lotName'] = session['parkingLotName'][:10]
            payload['aps']['content-state']['discount'] = None
        
        return payload
        
    except Exception as e:
        print(f"❌ Payload creation error: {str(e)}")
        return {'aps': {'timestamp': int(time.time()), 'event': 'update'}}


def send_push(push_token, activity_id, payload):
    """
    APNs로 Push 전송
    """
    try:
        if not all([APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_KEY]):
            print("❌ APNs configuration missing")
            return False
        
        # JWT 토큰 생성
        token = jwt.encode(
            {
                'iss': APNS_TEAM_ID,
                'iat': int(time.time())
            },
            APNS_KEY,
            algorithm='ES256',
            headers={
                'alg': 'ES256',
                'kid': APNS_KEY_ID
            }
        )
        
        # APNs URL 결정
        if APNS_ENVIRONMENT == 'sandbox':
            apns_url = 'https://api.sandbox.push.apple.com'
        else:
            apns_url = 'https://api.push.apple.com'
        
        url = f'{apns_url}/3/device/{push_token}'
        
        headers = {
            'authorization': f'bearer {token}',
            'apns-push-type': 'liveactivity',
            'apns-topic': f'{APNS_BUNDLE_ID}.push-type.liveactivity',
            'apns-priority': '10'
        }
        
        print(f"📤 Sending push to: {push_token[:16]}...")
        
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        
        if response.status_code == 200:
            print(f"✅ Push sent successfully")
            return True
        else:
            print(f"❌ Push failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Push sending error: {str(e)}")
        return False


def calculate_next_update(session):
    """
    다음 업데이트 필요 시점 계산
    """
    try:
        start_time_str = session['startTime']
        if start_time_str.endswith('Z'):
            start_time_str = start_time_str[:-1] + '+00:00'
        start_time = datetime.fromisoformat(start_time_str)
        
        now = datetime.now(start_time.tzinfo) if start_time.tzinfo else datetime.now()
        elapsed_seconds = (now - start_time).total_seconds()
        elapsed_minutes = int(elapsed_seconds / 60)
        
        config = session['feeConfig']
        additional_free = session.get('additionalFreeMinutes', 0)
        total_free_minutes = config['freeMinutes'] + additional_free
        
        # 8시간 제한 체크 (먼저 확인)
        if elapsed_seconds >= 8 * 3600:
            print("🕐 8-hour limit reached, no more updates")
            return None
        
        # 무료 시간이 아직 남아있으면 무료 시간 끝
        if elapsed_minutes < total_free_minutes:
            next_time = start_time + timedelta(minutes=total_free_minutes)
            print(f"⏰ Next update: free period ends at {next_time}")
            return next_time
        
        # 과금 시간 계산
        billable_minutes = elapsed_minutes - total_free_minutes
        
        # 초기 요금 구간이 아직 남아있으면 초기 구간 끝
        if billable_minutes < config['initialMinutes']:
            next_time = start_time + timedelta(minutes=total_free_minutes + config['initialMinutes'])
            print(f"⏰ Next update: initial period ends at {next_time}")
            return next_time
        
        # 추가 요금 구간의 다음 시점
        extra_minutes = billable_minutes - config['initialMinutes']
        current_unit = extra_minutes // config['additionalMinutes']
        next_unit_minutes = (current_unit + 1) * config['additionalMinutes']
        
        next_time = start_time + timedelta(
            minutes=total_free_minutes + config['initialMinutes'] + next_unit_minutes
        )
        
        # 8시간 제한 재확인
        if (next_time - start_time).total_seconds() >= 8 * 3600:
            print("🕐 Next update would exceed 8-hour limit")
            return None
        
        print(f"⏰ Next update: additional unit at {next_time}")
        return next_time
        
    except Exception as e:
        print(f"❌ Next update calculation error: {str(e)}")
        return None


def schedule_next_update(session_id, next_time):
    """
    다음 업데이트 스케줄링
    """
    try:
        schedule_name = f'parking-{session_id}'
        
        # Lambda 함수 ARN과 Role ARN (환경변수에서)
        push_sender_arn = os.environ.get('PUSH_SENDER_LAMBDA_ARN')
        eventbridge_role_arn = os.environ.get('EVENTBRIDGE_ROLE_ARN')
        
        if not push_sender_arn or not eventbridge_role_arn:
            print("❌ Missing ARNs for scheduling")
            return False
        
        # UTC 시간으로 변환
        if next_time.tzinfo is None:
            next_time = next_time.replace(tzinfo=datetime.now().astimezone().tzinfo)
        
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
        
        print(f"⏰ Next schedule created: {schedule_name} at {next_time}")
        return True
        
    except Exception as e:
        print(f"❌ Scheduling error: {str(e)}")
        return False