# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ParkingFeeCalculator is an iOS SwiftUI application for calculating parking fees with live activities and widget support. The app allows users to manage parking lots, calculate fees based on various conditions, and track active parking sessions through widgets and live activities.

## Quick Reference

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Minimum iOS**: 16.0+
- **Architecture**: MVVM
- **Data Storage**: UserDefaults with App Groups
- **Package Manager**: None (native iOS frameworks only)

## Development Commands

### Build and Run
```bash
# Open project in Xcode
open ParkingFeeCalculator.xcodeproj

# Build from command line (optional)
xcodebuild -project ParkingFeeCalculator.xcodeproj -scheme ParkingFeeCalculator -configuration Debug build

# Run tests
xcodebuild test -project ParkingFeeCalculator.xcodeproj -scheme ParkingFeeCalculator -destination 'platform=iOS Simulator,name=iPhone 15'
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

- App requires iOS 16+ for Live Activities support (`NSSupportsLiveActivities` in Info.plist)
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
- Code review protocols
- Continuous integration/deployment pipeline
- Documentation standards
- Unit test coverage requirements

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

### File Editing Guidelines
- Do what has been asked; nothing more, nothing less
- NEVER create files unless absolutely necessary
- ALWAYS prefer editing existing files over creating new ones
- NEVER proactively create documentation files unless explicitly requested

### Testing Checklist
- [ ] Main app launches without crashes
- [ ] Widgets display correct data
- [ ] Live activities update in real-time
- [ ] Fee calculations are accurate
- [ ] Data persists between app launches
- [ ] App Groups data sharing works correctly