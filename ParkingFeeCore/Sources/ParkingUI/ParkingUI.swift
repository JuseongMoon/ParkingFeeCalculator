//
//  ParkingUI.swift
//  ParkingUI
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import ParkingDomain
import ParkingData
import ParkingShared

// MARK: - UI Layer Public API
// 이 파일은 ParkingUI 패키지의 공개 API를 정의합니다

/// 패키지 버전 정보
public enum ParkingUIVersion {
    public static let version = "1.0.0"
    public static let buildNumber = 1
}

// MARK: - Use Case Implementations
// Use Case 구현체들은 각각의 파일에서 public으로 선언되어 있음
// - ManageParkingLotsUseCaseImpl
// - CalculateParkingFeeUseCaseImpl
// - ManageParkingSessionUseCaseImpl
// - ManageUserProfileUseCaseImpl

// MARK: - ViewModels (Future)
// ViewModel들이 추가될 때 이곳에서 관리
// 예: ParkingLotViewModel, SessionViewModel 등

// MARK: - UI Layer DI Configuration
/// UI Layer의 의존성 주입 설정
public struct UILayerDIConfiguration: DIConfiguration {
    public init() {}

    public func registerDependencies(in container: DIContainer) {
        // Use Case 구현체들 등록
        container.registerTransient(ManageParkingLotsUseCase.self) {
            ManageParkingLotsUseCaseImpl(
                parkingLotRepository: container.forceResolve(ParkingLotRepository.self)
            )
        }

        container.registerTransient(CalculateParkingFeeUseCase.self) {
            CalculateParkingFeeUseCaseImpl()
        }

        container.registerTransient(ManageParkingSessionUseCase.self) {
            ManageParkingSessionUseCaseImpl(
                sessionRepository: container.forceResolve(ParkingSessionRepository.self)
            )
        }

        container.registerTransient(ManageUserProfileUseCase.self) {
            ManageUserProfileUseCaseImpl(
                userProfileRepository: container.forceResolve(UserProfileRepository.self)
            )
        }

        print("🎯 [UILayer] Use Case 의존성들 등록 완료")
    }
}

// MARK: - App Configuration Helper
/// 전체 앱의 DI 설정을 도와주는 헬퍼
public struct ParkingAppDIConfiguration: DIConfiguration {
    public init() {}

    public func registerDependencies(in container: DIContainer) {
        // 모든 레이어의 의존성을 순차적으로 등록
        // 1. Data Layer (Repository 구현체들)
        DataLayerDIConfiguration().registerDependencies(in: container)

        // 2. UI Layer (Use Case 구현체들)
        UILayerDIConfiguration().registerDependencies(in: container)

        print("🚀 [ParkingApp] 모든 의존성 등록 완료")
    }
}

// MARK: - UI Layer Errors
/// UI Layer의 추가 에러 타입들
public enum UILayerError: Error, Equatable {
    case useCaseUnavailable
    case invalidViewModelState
    case userInteractionFailed(String)

    public var localizedDescription: String {
        switch self {
        case .useCaseUnavailable:
            return "Use Case를 사용할 수 없습니다"
        case .invalidViewModelState:
            return "ViewModel 상태가 올바르지 않습니다"
        case .userInteractionFailed(let details):
            return "사용자 상호작용 실패: \(details)"
        }
    }
}