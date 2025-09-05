# APNs 설정 가이드

## 1. Apple Developer Console에서 APNs 키 생성

### 1.1 APNs 인증서 생성
1. [Apple Developer Console](https://developer.apple.com/account/resources/authkeys/list) 접속
2. "Keys" 섹션으로 이동
3. "+" 버튼 클릭하여 새 키 생성
4. Key Name 입력 (예: "ParkingApp APNs Key")
5. **Apple Push Notifications service (APNs)** 체크박스 선택
6. "Continue" → "Register" 클릭
7. **중요**: .p8 파일 다운로드 (한 번만 가능)

### 1.2 필수 정보 수집
생성된 키에서 다음 정보 확인:
- **Key ID**: 10자리 문자열 (예: 2X9R4HXF34)
- **Team ID**: Apple Developer 계정의 Team ID
- **Bundle ID**: 앱의 Bundle Identifier
- **Private Key**: 다운로드한 .p8 파일 내용

## 2. APNs Private Key 변환

### 2.1 .p8 파일 내용 확인
```bash
cat AuthKey_2X9R4HXF34.p8
```

출력 예시:
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
...여러 줄의 키 데이터...
-----END PRIVATE KEY-----
```

### 2.2 환경 변수용 형식 변환
개행 문자를 `\n`으로 변환:

**macOS/Linux:**
```bash
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' AuthKey_2X9R4HXF34.p8
```

**결과 예시:**
```
-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...\n-----END PRIVATE KEY-----
```

## 3. 환경 변수 설정

### 3.1 .env 파일 생성 (로컬 개발용)
```bash
# .env 파일 생성
cat > .env << 'EOF'
APNS_KEY_ID=2X9R4HXF34
APNS_TEAM_ID=3MX8QZ9XYZ
APNS_BUNDLE_ID=com.ScienceFiction.ParkingFeeCalculator
APNS_ENVIRONMENT=sandbox
APNS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...\n-----END PRIVATE KEY-----"
EOF
```

### 3.2 배포용 환경 변수 설정
```bash
# AWS CLI를 통한 설정
export APNS_KEY_ID="2X9R4HXF34"
export APNS_TEAM_ID="3MX8QZ9XYZ"
export APNS_BUNDLE_ID="com.ScienceFiction.ParkingFeeCalculator"
export APNS_ENVIRONMENT="production"  # 또는 "sandbox"
export APNS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...\n-----END PRIVATE KEY-----"
```

## 4. 환경별 설정

### 4.1 개발 환경 (Sandbox)
- APNs URL: `https://api.sandbox.push.apple.com`
- TestFlight 빌드에서 테스트
- Bundle ID는 동일해야 함

### 4.2 프로덕션 환경
- APNs URL: `https://api.push.apple.com`
- App Store 배포 또는 Ad Hoc 빌드에서 사용

## 5. 검증 스크립트

### 5.1 APNs 연결 테스트
```python
# test_apns.py
import jwt
import time
import requests
import os

# 환경 변수 로드
APNS_KEY_ID = os.environ['APNS_KEY_ID']
APNS_TEAM_ID = os.environ['APNS_TEAM_ID']  
APNS_BUNDLE_ID = os.environ['APNS_BUNDLE_ID']
APNS_PRIVATE_KEY = os.environ['APNS_PRIVATE_KEY']

# JWT 토큰 생성
token = jwt.encode(
    {'iss': APNS_TEAM_ID, 'iat': int(time.time())},
    APNS_PRIVATE_KEY,
    algorithm='ES256',
    headers={'alg': 'ES256', 'kid': APNS_KEY_ID}
)

print(f"JWT Token: {token[:50]}...")
print("APNs 설정이 올바르게 구성되었습니다!")
```

### 5.2 실행
```bash
python test_apns.py
```

## 6. 보안 주의사항

### 6.1 Private Key 보관
- .p8 파일은 안전한 곳에 보관
- Git 저장소에 커밋하지 말 것
- AWS Secrets Manager 사용 권장 (프로덕션)

### 6.2 .gitignore 설정
```gitignore
# APNs Keys
*.p8
.env
AuthKey_*
```

## 7. 문제 해결

### 7.1 자주 발생하는 오류
- **403 Forbidden**: Team ID 또는 Key ID 불일치
- **400 Bad Request**: JWT 형식 오류 또는 Bundle ID 불일치
- **410 Gone**: 잘못된 Push Token 또는 만료된 토큰

### 7.2 디버깅 팁
```python
# APNs 응답 로깅
response = requests.post(url, json=payload, headers=headers)
print(f"Status: {response.status_code}")
print(f"Headers: {response.headers}")
print(f"Response: {response.text}")
```

## 8. iOS 앱 설정 확인

### 8.1 필수 Capability
- Push Notifications
- Background App Refresh (선택사항)

### 8.2 Info.plist 설정
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

### 8.3 Entitlements 확인
```xml
<key>com.apple.developer.usernotifications.live-activities</key>
<true/>
```