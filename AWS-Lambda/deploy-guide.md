# AWS Lambda 배포 가이드

## 🚀 빠른 시작

### 1. 사전 요구사항
```bash
# Node.js 설치 확인 (v16 이상)
node --version
npm --version

# Python 설치 확인 (3.9 이상)
python3 --version
pip3 --version

# AWS CLI 설치 및 설정
aws --version
aws configure list
```

### 2. 프로젝트 초기화
```bash
# 1. 프로젝트 디렉토리로 이동
cd /Users/david/Development/Swift/myProjects/ParkingFeeCalculator/AWS-Lambda

# 2. Node.js 의존성 설치
npm install

# 3. Serverless Framework 전역 설치
npm install -g serverless

# 4. Python 의존성 확인
pip3 install -r requirements.txt
```

## 🔑 APNs 설정 (필수)

### 3. APNs 키 설정
상세한 APNs 설정은 `apns-setup.md` 참조

```bash
# 환경 변수 설정 (실제 값으로 교체)
export APNS_KEY_ID="YOUR_KEY_ID"
export APNS_TEAM_ID="YOUR_TEAM_ID" 
export APNS_BUNDLE_ID="com.ScienceFiction.ParkingFeeCalculator"
export APNS_ENVIRONMENT="sandbox"  # 개발용, 프로덕션은 "production"
export APNS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----"
```

### 4. 환경 변수 검증
```bash
# APNs 설정 확인 스크립트
cat > verify_apns.py << 'EOF'
import os
import jwt
import time

required_vars = ['APNS_KEY_ID', 'APNS_TEAM_ID', 'APNS_BUNDLE_ID', 'APNS_PRIVATE_KEY']
missing = [var for var in required_vars if not os.environ.get(var)]

if missing:
    print(f"❌ Missing environment variables: {missing}")
    exit(1)

try:
    token = jwt.encode(
        {'iss': os.environ['APNS_TEAM_ID'], 'iat': int(time.time())},
        os.environ['APNS_PRIVATE_KEY'],
        algorithm='ES256',
        headers={'alg': 'ES256', 'kid': os.environ['APNS_KEY_ID']}
    )
    print(f"✅ APNs configuration verified!")
    print(f"JWT Token: {token[:50]}...")
except Exception as e:
    print(f"❌ APNs configuration error: {str(e)}")
EOF

python3 verify_apns.py
```

## 🚚 배포 단계별 가이드

### 5. 개발 환경 배포
```bash
# 개발 스택 배포
serverless deploy --stage dev

# 배포 완료 후 출력되는 API 엔드포인트 확인
# 예시: https://abc123def4.execute-api.ap-northeast-2.amazonaws.com/dev
```

### 6. 배포 결과 확인
```bash
# Lambda 함수 목록 확인
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `parking-push-service-dev`)].FunctionName'

# DynamoDB 테이블 확인
aws dynamodb describe-table --table-name ParkingSessions

# API Gateway 엔드포인트 테스트
API_URL="YOUR_API_GATEWAY_URL"  # 배포 시 출력된 URL
curl -X POST $API_URL/sessions/start \
  -H "Content-Type: application/json" \
  -d @test-session.json
```

## 📝 테스트 데이터

### 7. 테스트용 세션 데이터 생성
```bash
cat > test-session.json << 'EOF'
{
  "sessionId": "test-session-001",
  "startTime": "2025-01-01T09:00:00Z",
  "parkingLotId": "lot-123",
  "parkingLotName": "테스트 주차장",
  "vehicleProfile": {
    "type": "sedan",
    "isElectric": false,
    "isCompact": false
  },
  "driverProfile": {
    "hasDisabilityDiscount": false,
    "hasSeniorDiscount": false,
    "hasLowIncomeDiscount": false,
    "hasMultiChildDiscount": false,
    "hasNationalMeritDiscount": false
  },
  "additionalFreeMinutes": 0,
  "feeCalculatorConfig": {
    "freeMinutes": 30,
    "initialMinutes": 60,
    "initialFee": 1000,
    "additionalMinutes": 30,
    "additionalFee": 500,
    "maxFee": 10000,
    "hasNightRate": false
  }
}
EOF
```

### 8. API 테스트
```bash
# 1. 세션 시작
API_URL="https://YOUR_API_ID.execute-api.ap-northeast-2.amazonaws.com/dev"

curl -X POST $API_URL/sessions/start \
  -H "Content-Type: application/json" \
  -d @test-session.json

# 2. Push Token 업데이트
curl -X PUT $API_URL/sessions/test-session-001/push-token \
  -H "Content-Type: application/json" \
  -d '{
    "activityId": "activity-123",
    "pushToken": "1234567890abcdef1234567890abcdef12345678",
    "bundleId": "com.ScienceFiction.ParkingFeeCalculator"
  }'

# 3. 세션 종료
curl -X POST $API_URL/sessions/test-session-001/end \
  -H "Content-Type: application/json" \
  -d '{"timestamp": 1672574400}'
```

## 🏭 프로덕션 배포

### 9. 프로덕션 환경 설정
```bash
# 프로덕션 APNs 설정
export APNS_ENVIRONMENT="production"

# 프로덕션 배포
serverless deploy --stage prod
```

### 10. iOS 앱 설정 업데이트
배포 완료 후 iOS 앱의 `NetworkService.swift`에서 baseURL 업데이트:

```swift
// NetworkService.swift
private let baseURL = "https://YOUR_PROD_API_ID.execute-api.ap-northeast-2.amazonaws.com/prod"
```

## 📊 모니터링 및 로그

### 11. CloudWatch 로그 확인
```bash
# 실시간 로그 모니터링
serverless logs -f parkingSessionHandler -t
serverless logs -f parkingPushSender -t

# 특정 시간대 로그 조회
aws logs filter-log-events \
  --log-group-name "/aws/lambda/parking-push-service-dev-parkingSessionHandler" \
  --start-time $(date -d '1 hour ago' +%s)000
```

### 12. DynamoDB 데이터 확인
```bash
# 모든 세션 조회
aws dynamodb scan --table-name ParkingSessions

# 특정 세션 조회
aws dynamodb get-item \
  --table-name ParkingSessions \
  --key '{"sessionId": {"S": "test-session-001"}}'
```

### 13. EventBridge 스케줄 확인
```bash
# 활성 스케줄 목록
aws scheduler list-schedules --query 'Schedules[?starts_with(Name, `parking-`)].Name'

# 특정 스케줄 상세 정보
aws scheduler get-schedule --name "parking-test-session-001"
```

## 🔧 문제 해결

### 14. 자주 발생하는 오류

#### Lambda 함수 오류
```bash
# Lambda 함수 직접 테스트
serverless invoke -f parkingSessionHandler -d @test-session.json

# 에러 로그 확인
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/parking-push-service"
```

#### DynamoDB 권한 오류
```bash
# IAM 역할 확인
aws iam get-role --role-name parking-push-service-dev-ap-northeast-2-lambdaRole
```

#### APNs 연결 오류
```bash
# APNs 설정 재검증
python3 verify_apns.py

# 환경 변수 확인
aws lambda get-function-configuration \
  --function-name parking-push-service-dev-parkingPushSender \
  --query 'Environment.Variables'
```

### 15. 성능 최적화

#### Lambda 콜드 스타트 최소화
```bash
# Lambda 함수 워밍업 (선택사항)
serverless invoke -f parkingPushSender -d '{"sessionId": "warmup"}'
```

#### DynamoDB 성능 모니터링
```bash
# DynamoDB 메트릭 확인
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=ParkingSessions \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## 📱 iOS 앱 연동 테스트

### 16. 실제 기기에서 테스트
1. iOS 앱 빌드 및 설치
2. 주차 세션 시작
3. Lambda 로그에서 Push Token 등록 확인
4. Live Activity 업데이트 동작 확인

### 17. 배포 완료 체크리스트
- [ ] Lambda 함수 정상 배포 확인
- [ ] DynamoDB 테이블 생성 확인
- [ ] API Gateway 엔드포인트 응답 확인
- [ ] APNs Push 전송 성공 확인
- [ ] EventBridge 스케줄 생성 확인
- [ ] iOS 앱에서 Live Activity 업데이트 확인
- [ ] CloudWatch 로그 정상 출력 확인

## 🗑️ 리소스 정리

### 18. 스택 삭제 (필요시)
```bash
# 개발 환경 삭제
serverless remove --stage dev

# 프로덕션 환경 삭제
serverless remove --stage prod
```

배포가 완료되면 iOS 앱에서 실제 Push 업데이트를 받을 수 있습니다!