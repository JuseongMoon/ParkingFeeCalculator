# ParkingFeeCalculator

주차장마다 제각각인 요금 체계를 등록해두고, **지금 나가면 얼마인지**를
잠금화면과 다이내믹 아일랜드에서 실시간으로 확인하는 iOS 앱입니다.

- 플랫폼: iOS 16.0+ (SwiftUI)
- 구성: 앱 + WidgetKit 확장 + Clean Architecture SPM 패키지 + AWS 서버리스 백엔드
- 간소화 버전: [ParkingFeeCalculatorLight](https://github.com/JuseongMoon/ParkingFeeCalculatorLight)

## 이 앱이 푸는 문제

주차 요금표는 생각보다 복잡합니다. "최초 30분 1,000원, 이후 10분당 500원,
일 최대 15,000원, 22시~08시는 정액 5,000원, 최초 15분 무료" 같은 식입니다.
계산기를 두드리거나 그냥 포기하게 됩니다.

이 앱은 그 규칙을 **한 번 등록해두면 타이머만 켜면 되는 것**으로 바꿉니다.

## 요금 모델

| 항목 | 필드 |
| --- | --- |
| 기본 요금 | `initialFee` / `initialMinutes` |
| 추가 요금 | `additionalFee` / `additionalMinutes` |
| 무료 시간 | `freeMinutes` |
| 상한 | `maxFee` / `dailyMaxFee` |
| 야간 요금 | `nightStartHour` ~ `nightEndHour` + `nightRateType` |
| 시간대별 차등 | `pricingTiers: [TimeBasedPricingTier]` |

야간 요금은 **정액(`flat`)과 할인율(`percentage`) 두 방식**을 모두 지원합니다.
주차장마다 표기 방식이 달라 하나로 통일할 수 없었기 때문입니다.

`useTimeBasedPricing`을 켜면 단순 "초과 N분당 M원" 대신
`thresholdMinutes` 기준으로 구간별 단가가 바뀌는 계단식 요금을 적용합니다.

## 기술적으로 다룬 것

**1. Live Activity를 서버 푸시로 갱신하는 서버리스 백엔드**
주차 중에는 요금이 계속 오릅니다. 앱이 백그라운드에 있어도 잠금화면 숫자가
정확해야 하는데, iOS는 백그라운드 실행 시간을 보장하지 않습니다.

그래서 **요금이 바뀌는 시점을 미리 계산해 그때마다 푸시를 예약**하는 구조를 만들었습니다.

```
iOS App → API Gateway → Lambda #1 (세션 관리)
                          ↓
             EventBridge Scheduler → Lambda #2 (Push 전송) → APNs
                          ↓
                     DynamoDB (세션 저장)
```

EventBridge로 다음 요금 변경 시점에 스케줄을 걸고, 푸시를 보낼 때 그다음 시점을
다시 예약하는 **체인 스케줄링**입니다. 세션 데이터는 9시간 후 자동 삭제됩니다.
→ [`AWS-Lambda/`](AWS-Lambda/)

**2. Clean Architecture로 계층 분리 (SPM 로컬 패키지)**
앱 본체, 위젯 확장, Live Activity가 같은 도메인 로직을 써야 했습니다.
타겟마다 파일을 중복 포함하는 대신 로컬 SPM 패키지로 분리했습니다.

```
ParkingFeeCore/Sources/
├── ParkingDomain/   엔티티와 유스케이스 (의존성 없음)
├── ParkingData/     Repository 구현 · UserDefaults 데이터소스 · Mapper
├── ParkingFeeCore/  요금 계산기 · 세션 동기화 · 변경 알림
├── ParkingUI/       공용 뷰
└── ParkingShared/   ActivityKit Attributes 등 앱↔위젯 공유 타입
```

`ParkingDomain`은 어떤 프레임워크에도 의존하지 않아, 요금 계산 규칙을
UI나 저장소 없이 단독으로 테스트합니다. → [`ParkingFeeCore/Tests/`](ParkingFeeCore/Tests/)

**3. App Groups로 앱과 위젯이 같은 데이터를 본다**
위젯 확장은 별도 프로세스라 앱의 메모리 상태를 볼 수 없습니다.
App Group 컨테이너의 UserDefaults를 통해 주차장 프로필과 활성 세션을 공유하고,
`DataChangeNotifier`가 변경을 양쪽에 전파합니다.

## 구조

```
├── ParkingFeeCalculator/       앱 본체 (주차장 관리 · 타이머 · 설정 · 위젯 뷰)
├── ParkingFeeCalculatorWidget/ WidgetKit 확장 · Live Activity
├── ParkingFeeCore/             Clean Architecture SPM 패키지 + 테스트
└── AWS-Lambda/                 세션 관리 · APNs 푸시 전송 (Python, Serverless)
```

## 기술 스택

**iOS** SwiftUI · WidgetKit · ActivityKit · App Groups · Swift Package Manager
**백엔드** AWS Lambda(Python) · API Gateway · EventBridge Scheduler · DynamoDB · APNs

## 실행 방법

```bash
git clone https://github.com/JuseongMoon/ParkingFeeCalculator.git
cd ParkingFeeCalculator
open ParkingFeeCalculator.xcodeproj
```

앱과 요금 계산은 그대로 빌드됩니다. Live Activity는 실제 기기에서만 동작합니다.

푸시 백엔드까지 돌리려면 Apple Developer 계정의 APNs 인증 키(`.p8`)와
Team ID / Key ID가 필요합니다. 설정 절차는 [`AWS-Lambda/apns-setup.md`](AWS-Lambda/apns-setup.md)에
있고, `.p8` 파일과 자격증명은 `.gitignore` 대상이라 저장소에 포함되지 않습니다.

## 라이선스

MIT License. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요.
