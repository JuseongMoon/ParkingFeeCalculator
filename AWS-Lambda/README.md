# 🚗 Parking Push Service - AWS Lambda

iOS 주차 요금 계산기를 위한 실시간 Push 업데이트 서비스입니다.

## 🏗️ 아키텍처

```
iOS App → API Gateway → Lambda #1 (세션 관리)
                         ↓
              EventBridge Scheduler → Lambda #2 (Push 전송) → APNs
                         ↓
                    DynamoDB (세션 저장)
```

## ⚡ 핵심 기능

- **실시간 Push**: ActivityKit을 통한 Live Activity 업데이트
- **체인 스케줄링**: EventBridge로 요금 변경 시점마다 자동 업데이트
- **심플 구조**: Lambda 2개, DynamoDB 1개로 최소 구성
- **자동 정리**: 9시간 후 세션 데이터 자동 삭제
- **4KB 최적화**: APNs 페이로드 크기 제한 준수

## 📁 파일 구조

```
AWS-Lambda/
├── parking_session_handler.py   # 세션 관리 Lambda
├── parking_push_sender.py       # Push 전송 Lambda  
├── serverless.yml               # Serverless 배포 설정
├── requirements.txt             # Python 의존성
├── package.json                # Node.js 설정
├── apns-setup.md               # APNs 설정 가이드
├── deploy-guide.md             # 배포 가이드
└── README.md                   # 이 문서
```

## 🚀 빠른 시작

### 1. 환경 설정
```bash
# APNs 환경 변수 설정 (실제 값으로 교체)
export APNS_KEY_ID="YOUR_KEY_ID"
export APNS_TEAM_ID="YOUR_TEAM_ID"
export APNS_BUNDLE_ID="com.ScienceFiction.ParkingFeeCalculator"
export APNS_ENVIRONMENT="sandbox"
export APNS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
```

### 2. 배포
```bash
# 의존성 설치
npm install

# 개발 환경 배포
serverless deploy --stage dev
```

### 3. iOS 앱 연동
배포된 API Gateway URL을 iOS 앱의 `NetworkService.swift`에서 업데이트:

```swift
private let baseURL = "https://YOUR_API_ID.execute-api.ap-northeast-2.amazonaws.com/dev"
```

## 📋 API 엔드포인트

### POST /sessions/start
주차 세션 시작 및 첫 업데이트 스케줄링

### PUT /sessions/{sessionId}/push-token
Push Token 업데이트 (ActivityKit에서 자동 호출)

### POST /sessions/{sessionId}/end
주차 세션 종료 및 스케줄 삭제

## 📊 DynamoDB 스키마

```json
{
  "sessionId": "uuid",
  "startTime": "2025-01-01T09:00:00Z",
  "parkingLotName": "주차장명",
  "feeConfig": {...},
  "discountRate": 50,
  "pushToken": "apns_token",
  "activityId": "activity_id",
  "status": "active|ended",
  "ttl": 1672574400
}
```

## 🔧 운영 명령어

```bash
# 로그 모니터링
serverless logs -f parkingPushSender -t

# 함수 직접 호출
serverless invoke -f parkingSessionHandler -d @test-session.json

# 스택 삭제
serverless remove --stage dev
```

## 📱 테스트 방법

1. **API 테스트**: `curl` 명령으로 세션 생성
2. **Push 테스트**: iOS 시뮬레이터에서 Live Activity 확인  
3. **로그 확인**: CloudWatch에서 실시간 로그 모니터링

## 🔍 문제 해결

- **APNs 연결 실패**: `apns-setup.md` 참조하여 인증서 재확인
- **권한 오류**: IAM 역할에 DynamoDB/EventBridge 권한 확인
- **페이로드 초과**: 4KB 제한으로 필드 길이 체크

## 📚 상세 가이드

- [APNs 설정 가이드](apns-setup.md)
- [배포 가이드](deploy-guide.md)

## 💰 예상 비용

월 10,000명 사용자 기준:
- Lambda 실행: ~$0.10
- DynamoDB: ~$3.00
- EventBridge: ~$0.30
- **총합: ~$3.40/월**

---

**배포 완료 후 iOS 앱에서 완전 자동화된 실시간 주차 요금 업데이트를 경험하세요!** 🎉