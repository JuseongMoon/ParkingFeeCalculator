//
//  DriverProfile.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import Foundation

struct DriverProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var isDisabled: Bool
    var disabilityLevel: DisabilityLevel?
    var isNationalMerit: Bool
    var isExemplaryTaxpayer: Bool
    var isMultiChild: Bool
    var isSenior: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        isDisabled: Bool = false,
        disabilityLevel: DisabilityLevel? = nil,
        isNationalMerit: Bool = false,
        isExemplaryTaxpayer: Bool = false,
        isMultiChild: Bool = false,
        isSenior: Bool = false
    ) {
        self.isDisabled = isDisabled
        self.disabilityLevel = disabilityLevel
        self.isNationalMerit = isNationalMerit
        self.isExemplaryTaxpayer = isExemplaryTaxpayer
        self.isMultiChild = isMultiChild
        self.isSenior = isSenior
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum DisabilityLevel: String, CaseIterable, Codable {
    case mild = "mild"
    case severe = "severe"
    
    var displayName: String {
        switch self {
        case .mild:
            return "경증"
        case .severe:
            return "중증"
        }
    }
    
    var discountPercentage: Double {
        switch self {
        case .mild:
            return 20.0 // 경증 20% 할인
        case .severe:
            return 50.0 // 중증 50% 할인
        }
    }
}

// MARK: - DriverProfile Extensions
extension DriverProfile {
    var isProfileComplete: Bool {
        return true // 특별 조건만 있으면 완성된 것으로 간주
    }
    
    var displayName: String {
        var descriptions: [String] = []
        
        if isDisabled {
            if let level = disabilityLevel {
                descriptions.append("\(level.displayName) 장애인")
            } else {
                descriptions.append("장애인")
            }
        }
        
        if isNationalMerit {
            descriptions.append("국가유공자")
        }
        
        if isExemplaryTaxpayer {
            descriptions.append("모범납세자")
        }
        
        if isMultiChild {
            descriptions.append("다자녀")
        }
        
        if isSenior {
            descriptions.append("고령자")
        }
        
        if descriptions.isEmpty {
            return "일반 운전자"
        } else {
            return descriptions.joined(separator: ", ") + " 운전자"
        }
    }
    
    var disabilityDiscountPercentage: Double {
        // 이제 주차장별 할인율을 사용하므로 기본값만 반환
        // 실제 할인율은 ParkingLotProfile.disabilityDiscounts에서 가져옴
        guard isDisabled, let level = disabilityLevel else { return 0.0 }
        return level.discountPercentage
    }
    
    var hasAnySpecialCondition: Bool {
        return isDisabled || isNationalMerit || isExemplaryTaxpayer || isMultiChild || isSenior
    }
    
    var specialConditionsCount: Int {
        var count = 0
        if isDisabled { count += 1 }
        if isNationalMerit { count += 1 }
        if isExemplaryTaxpayer { count += 1 }
        if isMultiChild { count += 1 }
        if isSenior { count += 1 }
        return count
    }
}

