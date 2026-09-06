# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ParkingFeeCalculator is an iOS SwiftUI application for calculating parking fees with live activities and widget support. The app allows users to manage parking lots, calculate fees based on various conditions, and track active parking sessions through widgets and live activities.

## Quick Reference

- **Language**: Swift (`SWIFT_VERSION = 5.0`)
- **Framework**: SwiftUI · WidgetKit · ActivityKit
- **Minimum iOS**: 18.5 (`IPHONEOS_DEPLOYMENT_TARGET`, app + widget extension)
- **Architecture**: MVVM in the app target; Clean Architecture in the `ParkingFeeCore` local SPM package
- **Data Storage**: UserDefaults with App Groups
- **Package Manager**: Swift Package Manager — local package `ParkingFeeCore/` (ParkingDomain · ParkingData · ParkingFeeCore · ParkingUI · ParkingShared)

> **The app target does not currently compile.** `VehicleSize` / `DisabilityLevel` are defined both in
> `ParkingFeeCalculator/Shared/BasicDataTypes.swift` and in the package, and `Setting/UserProfileView.swift`
> resolves to the app-local copies, which lack `displayName`. Deciding which definition is canonical is the
> next task. The `ParkingFeeCore` package itself builds and tests green.

## Development Commands

### Build and Run
```bash
# Open project in Xcode
open ParkingFeeCalculator.xcodeproj

# Build from command line (optional)
xcodebuild -project ParkingFeeCalculator.xcodeproj -scheme ParkingFeeCalculator -configuration Debug build

# Run package tests (the only tests in this repo — the Xcode project has no test target)
cd ParkingFeeCore && swift test
```

### Xcode Shortcuts
- Build: `Cmd+B`
- Run: `Cmd+R`
- Clean: `Cmd+Shift+K`
- Test: `Cmd+U`

### Targets
- **Main App**: `ParkingFeeCalculator` - Primary iOS application
- **Widget Extension**: `ParkingFeeCalculatorWidgetExtension` - WidgetKit extension for home screen widgets and live activities

## Architecture

### Project Structure
```
ParkingFeeCalculator/
├── Core/                 # Data models and business logic
│   ├── Models/          # Data structures
│   └── Services/        # Business services
├── Parking/             # Parking lot management
│   ├── Views/          # SwiftUI views
│   └── ViewModels/     # View models
├── Calculator/          # Fee calculation engine
├── Setting/            # User profile and app settings
├── Timer/              # Parking session tracking
├── Shared/             # Shared components between targets
└── Widget/             # Widget extension code
```

### Core Data Models
- `ParkingLotProfile`: Main parking lot entity with fee calculation settings and special discounts
- `ParkingFeeCalculator`: Fee calculation logic with time-based pricing (initial fees, additional fees, max fees, night rates)
- `SpecialConditionDiscounts`: Discount system for various user categories (disabled, senior, vehicle type, etc.)
- `DriverProfile` & `VehicleProfile`: User and vehicle information for discount calculations

### Main Components
- **MainTabView**: Root tab navigation (Parking Lots, Settings)
- **ParkingDataManager**: Singleton for data persistence and synchronization
- **LiveActivityManager**: Handles ActivityKit live activities
- **FeeCalculationEngine**: Core fee calculation logic with discount application

### Key Features
- **Live Activities**: Real-time parking session tracking in Dynamic Island/Lock Screen
- **Widgets**: Home screen widgets showing parking status
- **App Groups**: Data sharing between main app and extensions via `group.com.ScienceFiction.ParkingFeeCalculator`
- **UserDefaults Suite**: Persistent data storage shared across app and extensions
- **Complex Fee Calculation**: Multi-tier pricing with time periods, discounts, and special conditions

### Data Persistence
```swift
// Access shared UserDefaults
let sharedDefaults = UserDefaults(suiteName: "group.com.ScienceFiction.ParkingFeeCalculator")

// Key patterns used
"parkingLots"           // Array of ParkingLotProfile
"activeParkingSession"  // Current parking session
"userProfile"           // User settings and preferences
```

- `ParkingDataManager.shared` handles data synchronization between app and widgets
- JSON serialization for complex data structures
- Automatic widget timeline refresh on data changes

### Localization
- Korean language support (text in Korean throughout codebase)
- Uses Korean system image labels and text

## Widget and Live Activity Integration

The app includes sophisticated widget functionality:
- **Small/Medium Widgets**: Display current parking status and fees
- **Live Activities**: Real-time parking session updates using ActivityKit
- **Data Synchronization**: Automatic widget updates when parking data changes
- **Shared Components**: Widget views reuse main app components where possible

## Special Considerations

- Live Activities require `NSSupportsLiveActivities` in Info.plist (deployment target is iOS 18.5)
- Uses App Groups entitlement for data sharing between targets
- Notification permissions requested on app launch for parking alerts
- Color scheme management with system/light/dark mode support

## Code Style Guide

### Import Order
```swift
import SwiftUI
import WidgetKit
import ActivityKit
// Third-party imports (if any)
// Local imports
```

### View Structure Template
```swift
struct ExampleView: View {
    // MARK: - Properties
    @StateObject private var viewModel = ExampleViewModel()
    @State private var localState = false
    
    // MARK: - Body
    var body: some View {
        content
    }
    
    // MARK: - Views
    private var content: some View {
        // Main content here
    }
}
```

## iOS Development Guidelines

### Code Structure & Architecture
- Uses Swift's latest features and protocol-oriented programming
- Follows MVVM architecture with SwiftUI
- Prefers value types (structs) over classes
- Current structure: Core/, Parking/, Calculator/, Setting/, Timer/, Shared/, Widget/
- Adheres to Apple's Human Interface Guidelines

### Naming Conventions
- camelCase for variables/functions, PascalCase for types
- Verbs for methods (e.g., fetchData, calculateFee)
- Boolean properties use is/has/should prefixes
- Clear, descriptive names following Apple style guide

### Swift Best Practices
- Strong type system with proper optionals handling
- Uses async/await for concurrency where applicable
- Result type for error handling
- @Published, @StateObject for SwiftUI state management
- Prefers let over var for immutability
- Protocol extensions for shared functionality

### UI Development Standards
- SwiftUI-first approach (UIKit when needed)
- SF Symbols for consistent iconography
- Dark mode and dynamic type support
- SafeArea and GeometryReader for responsive layout
- Handles all screen sizes and orientations
- Proper keyboard handling implementation

### Performance Optimization
- Profile with Instruments for performance monitoring
- Lazy loading for views and images
- Optimized network requests
- Background task handling
- Proper state management to minimize re-renders
- Memory management best practices

### Data & State Management
- UserDefaults for app preferences and shared data
- Combine for reactive programming patterns
- Clean data flow architecture with MVVM
- Proper dependency injection
- State restoration handling

### Security Implementation
- Keychain services for sensitive data storage
- Input validation for user data
- App Transport Security compliance
- Biometric authentication where appropriate

### Testing & Quality Assurance
- XCTest for unit testing
- XCUITest for UI automation testing
- Test coverage for critical user flows
- Performance testing protocols
- Error scenario handling
- Accessibility testing compliance

### Essential iOS Features
- Deep linking support capability
- Push notification integration
- Background task execution
- Localization support (Korean)
- Comprehensive error handling
- Analytics and logging implementation

## Common Tasks

### Adding a New View
1. Create view file in appropriate folder (Parking/, Setting/, etc.)
2. Follow MVVM pattern - create ViewModel if needed
3. Add navigation link in parent view
4. Update preview provider for SwiftUI previews

### Modifying Fee Calculation
1. Update `ParkingFeeCalculator` model in Core/Models/
2. Test calculation logic in Calculator/
3. Update widget if fee display affected
4. Verify live activity updates correctly

### Widget Updates
1. Modify widget views in Widget/ folder
2. Update timeline provider if data refresh needed
3. Test on different widget sizes (small, medium)
4. Verify data synchronization via App Groups

### Development Process
- SwiftUI previews for rapid development
- Git version control with branching strategy
- **No CI.** There is no workflow in `.github/`; verify changes by building locally
  (`xcodebuild ... build`) and running `cd ParkingFeeCore && swift test`.
- **No coverage requirement.** The Xcode project has no test target; the only tests live in
  `ParkingFeeCore/Tests/` and cover the domain/fee-calculation layer.

### App Store Compliance
- Privacy policy descriptions
- Proper app capabilities declaration
- Review guidelines adherence
- App thinning optimization
- Code signing configuration

## Important Reminders

### When Making Changes
- ALWAYS test on iOS Simulator after code changes
- VERIFY widget updates when modifying shared data
- CHECK live activity functionality if timer logic changes
- MAINTAIN Korean localization for all user-facing text
- FOLLOW existing code patterns and architecture

### Testing Checklist
- [ ] Main app launches without crashes
- [ ] Widgets display correct data
- [ ] Live activities update in real-time
- [ ] Fee calculations are accurate
- [ ] Data persists between app launches
- [ ] App Groups data sharing works correctly

---

## 공개 저장소 규칙

이 저장소는 공개되어 있다. 커밋한 것은 되돌려도 남는다.

- **시크릿 금지** — API 키·토큰·서명 키(`*.jks`/`*.p12`)·서비스 계정 키·실제 사용자 데이터를 커밋하지 않는다.
  값은 **`Secrets.xcconfig`** 에만 두고 저장소에는 `*.example`만 올린다.
  소스·plist·manifest·주석·커밋 메시지 어디에도 값을 쓰지 않는다.
  이미 올렸다면 되돌리는 것으로 끝내지 말고 **키를 폐기·재발급**한다.
- **내부 정보 금지** — 로컬 절대경로(`/Users/…`), 저장소 밖 파일 참조, 관리자 URL,
  인프라 식별자(버킷·배포 ID·계정 번호), 개인 기기 식별자(UDID·시리얼),
  릴리스 진행 상태와 스토어 콘솔 절차는 문서에 남기지 않는다.
- **내부 문서 위치** — 가격 전략·미출시 기획·운영 절차·서버 계약은 저장소에 두지 않는다.
  로컬에 두고 gitignore 하되 **그 판단 근거를 이 문서에 적어** 다음 세션이 되돌리지 않게 한다.
  gitignore된 경로를 코드 주석이나 문서에서 참조하지 않는다 — 방문자에게는 끊어진 링크다.
- **문서 정확성** — 여기 적힌 버전·경로·명령·구조가 코드와 다르면 코드가 아니라 문서를 고친다.
  배포 타깃과 언어 버전은 프로젝트 기본값이 아니라 **앱 타깃의 실제 값**을 확인해 적는다.
- **브랜치** — 에이전트 작업 브랜치는 머지 후 지운다. 원격에 실험 브랜치를 남기지 않는다.
  **처음 push 하는 순간 그 브랜치의 문서·메모도 함께 공개된다.**
- **`main`에 force-push 하지 않는다.** 공개된 히스토리를 다시 쓰면 클론·포크한 쪽이 깨진다.
  (예외: 시크릿 제거 — 이때도 키 폐기가 먼저다.)
- **push 전 확인** — `git fetch origin && git status -sb`로 원격이 앞섰는지 보고, 앞섰으면 덮지 말고 rebase 한다.
  `git log origin/main..HEAD --stat`으로 올라갈 파일 전체를 확인해 무관한 파일을 분리하고,
  `git diff`에서 키·절대경로·기기 식별자가 없는지 본다. **`git add .` 금지.**