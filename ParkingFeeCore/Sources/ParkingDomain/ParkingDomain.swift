//
//  ParkingDomain.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation

// MARK: - Domain Layer Public API
// 이 파일은 ParkingDomain 패키지의 공개 API를 정의합니다

/// 패키지 버전 정보
public enum ParkingDomainVersion {
    public static let version = "1.0.0"
    public static let buildNumber = 1
}

// MARK: - Entities
// Domain 엔티티들은 각각의 파일에서 public으로 선언되어 있음
// - ParkingLotEntity
// - ParkingSessionEntity

// MARK: - Value Objects
// Domain Value Objects들은 각각의 파일에서 public으로 선언되어 있음
// - VehicleProfile, VehicleSize, VehicleFuelType
// - DriverProfile, SpecialCondition, DisabilityLevel
// - FeeCalculationRules, BasicFeeRules, NightRateRules, MaxFeeRules, TimeBasedPricingRules
// - DiscountRules, DriverDiscountRules, VehicleDiscountRules
// - FeeCalculationResult, DiscountInfo, DiscountType

// MARK: - Use Cases (Interfaces)
// Use Case 인터페이스들은 각각의 파일에서 public으로 선언되어 있음
// - ManageParkingLotsUseCase
// - CalculateParkingFeeUseCase
// - ManageParkingSessionUseCase
// - ManageUserProfileUseCase

// MARK: - Repository Interfaces
// Repository 인터페이스들은 각각의 파일에서 public으로 선언되어 있음
// - ParkingLotRepository
// - ParkingSessionRepository
// - UserProfileRepository

// MARK: - Domain Errors
/// Domain 계층의 에러 타입
public enum DomainError: Error, Equatable {
    case invalidInput(String)
    case businessRuleViolation(String)
    case entityNotFound(String)
    case calculationError(String)
    case sessionAlreadyExists
    case noActiveSession

    public var localizedDescription: String {
        switch self {
        case .invalidInput(let message):
            return "잘못된 입력: \(message)"
        case .businessRuleViolation(let message):
            return "비즈니스 규칙 위반: \(message)"
        case .entityNotFound(let message):
            return "엔티티를 찾을 수 없음: \(message)"
        case .calculationError(let message):
            return "계산 오류: \(message)"
        case .sessionAlreadyExists:
            return "이미 활성 세션이 존재합니다"
        case .noActiveSession:
            return "활성 세션이 없습니다"
        }
    }
}

// MARK: - Domain Services (Future)
/// Domain 서비스들이 추가될 때 이곳에서 관리
/// 예: FeeCalculationService, DiscountService 등