//
//  DriverProfile.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation

/// 운전자 프로필 Value Object
public struct DriverProfile: Equatable, Hashable, Codable {
    public let specialConditions: Set<SpecialCondition>

    public init(specialConditions: Set<SpecialCondition> = []) {
        self.specialConditions = specialConditions
    }
}

// MARK: - DriverProfile Extensions
public extension DriverProfile {
    var displayName: String {
        if specialConditions.isEmpty {
            return "일반 운전자"
        } else {
            let descriptions = specialConditions
                .sorted { $0.rawValue < $1.rawValue }
                .map { $0.displayName }
            return descriptions.joined(separator: ", ") + " 운전자"
        }
    }

    var hasAnySpecialCondition: Bool {
        return !specialConditions.isEmpty
    }

    // Legacy compatibility helpers
    var isDisabled: Bool {
        return specialConditions.contains(.mildDisability) || specialConditions.contains(.severeDisability)
    }

    var disabilityLevel: DisabilityLevel? {
        if specialConditions.contains(.severeDisability) { return .severe }
        if specialConditions.contains(.mildDisability) { return .mild }
        return nil
    }

    var isNationalMerit: Bool { specialConditions.contains(.nationalMerit) }
    var isExemplaryTaxpayer: Bool { specialConditions.contains(.exemplaryTaxpayer) }
    var isMultiChild: Bool { specialConditions.contains(.multiChild) }
    var isSenior: Bool { specialConditions.contains(.senior) }
}

/// 특수 조건 (할인 대상)
public enum SpecialCondition: String, CaseIterable, Codable, Hashable {
    case mildDisability = "mild_disability"
    case severeDisability = "severe_disability"
    case nationalMerit = "national_merit"
    case exemplaryTaxpayer = "exemplary_taxpayer"
    case multiChild = "multi_child"
    case senior = "senior"

    public var displayName: String {
        switch self {
        case .mildDisability: return "경증 장애인"
        case .severeDisability: return "중증 장애인"
        case .nationalMerit: return "국가유공자"
        case .exemplaryTaxpayer: return "모범납세자"
        case .multiChild: return "다자녀"
        case .senior: return "고령자"
        }
    }
}

/// 장애 수준 (Legacy compatibility)
public enum DisabilityLevel: String, CaseIterable, Codable {
    case mild = "mild"
    case severe = "severe"

    public var displayName: String {
        switch self {
        case .mild: return "경증"
        case .severe: return "중증"
        }
    }

    public var discountPercentage: Double {
        switch self {
        case .mild: return 20.0
        case .severe: return 50.0
        }
    }
}