//
//  ParkingFeeCalculator.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import Foundation

struct ParkingFeeCalculator: Codable, Identifiable {
    let id = UUID()
    var baseFee: Int
    var baseMinutes: Int
    var unitFee: Int
    var unitMinutes: Int
    var maxFee: Int?
    var freeMinutes: Int
    var dailyMaxFee: Int?
    var nightFlatFee: Int?
    var nightStartHour: Int?
    var nightEndHour: Int?
    var vehicleSizeMultipliers: [VehicleSize: Double]
    var specialDiscounts: [SpecialDiscount]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        baseFee: Int = 1000,
        baseMinutes: Int = 60,
        unitFee: Int = 500,
        unitMinutes: Int = 30,
        maxFee: Int? = nil,
        freeMinutes: Int = 0,
        dailyMaxFee: Int? = nil,
        nightFlatFee: Int? = nil,
        nightStartHour: Int? = nil,
        nightEndHour: Int? = nil,
        vehicleSizeMultipliers: [VehicleSize: Double] = [:],
        specialDiscounts: [SpecialDiscount] = []
    ) {
        self.baseFee = baseFee
        self.baseMinutes = baseMinutes
        self.unitFee = unitFee
        self.unitMinutes = unitMinutes
        self.maxFee = maxFee
        self.freeMinutes = freeMinutes
        self.dailyMaxFee = dailyMaxFee
        self.nightFlatFee = nightFlatFee
        self.nightStartHour = nightStartHour
        self.nightEndHour = nightEndHour
        self.vehicleSizeMultipliers = vehicleSizeMultipliers
        self.specialDiscounts = specialDiscounts
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct SpecialDiscount: Codable, Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var discountPercentage: Double
    var discountAmount: Int?
    var applicableConditions: [DiscountCondition]
    var isActive: Bool
    
    init(
        name: String = "",
        description: String = "",
        discountPercentage: Double = 0.0,
        discountAmount: Int? = nil,
        applicableConditions: [DiscountCondition] = [],
        isActive: Bool = true
    ) {
        self.name = name
        self.description = description
        self.discountPercentage = discountPercentage
        self.discountAmount = discountAmount
        self.applicableConditions = applicableConditions
        self.isActive = isActive
    }
}

enum DiscountCondition: Codable {
    case disabledDriver
    case mildDisabledDriver
    case severeDisabledDriver
    case nationalMerit
    case exemplaryTaxpayer
    case multiChild
    case senior
    case lowEmission
    case electricHydrogen
    case hybrid
            case specificVehicleSize(VehicleSize)
    case timeOfDay(startHour: Int, endHour: Int)
    case minimumDuration(TimeInterval)
    case maximumDuration(TimeInterval)
    case firstTimeUser
    case loyaltyMember
    
    var displayName: String {
        switch self {
        case .disabledDriver:
            return "장애인 운전자"
        case .mildDisabledDriver:
            return "경증 장애인 운전자"
        case .severeDisabledDriver:
            return "중증 장애인 운전자"
        case .nationalMerit:
            return "국가유공자"
        case .exemplaryTaxpayer:
            return "모범납세자"
        case .multiChild:
            return "다자녀"
        case .senior:
            return "고령자"
        case .lowEmission:
            return "저공해 인증"
        case .electricHydrogen:
            return "전기/수소"
        case .hybrid:
            return "하이브리드"
        case .specificVehicleSize(let size):
            return size.displayName
        case .timeOfDay(let startHour, let endHour):
            return "\(startHour)시~\(endHour)시"
        case .minimumDuration(let duration):
            let hours = Int(duration / 3600)
            return "\(hours)시간 이상"
        case .maximumDuration(let duration):
            let hours = Int(duration / 3600)
            return "\(hours)시간 이하"
        case .firstTimeUser:
            return "첫 이용자"
        case .loyaltyMember:
            return "로열티 회원"
        }
    }
}

// MARK: - ParkingFeeCalculator Extensions
extension ParkingFeeCalculator {
    var isProfileComplete: Bool {
        return baseFee > 0 && baseMinutes > 0 && unitFee > 0 && unitMinutes > 0
    }
    
    var hasNightRate: Bool {
        return nightFlatFee != nil && nightStartHour != nil && nightEndHour != nil
    }
    
    var hasDailyMax: Bool {
        return dailyMaxFee != nil
    }
    
    var hasMaxFee: Bool {
        return maxFee != nil
    }
    
    func getVehicleMultiplier(for vehicleSize: VehicleSize) -> Double {
        return vehicleSizeMultipliers[vehicleSize] ?? vehicleSize.defaultRateMultiplier
    }
    
    func isNightTime() -> Bool {
        guard let startHour = nightStartHour, let endHour = nightEndHour else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        if startHour <= endHour {
            return currentHour >= startHour && currentHour < endHour
        } else {
            // 자정을 넘어가는 경우 (예: 22시~06시)
            return currentHour >= startHour || currentHour < endHour
        }
    }
    
    mutating func setVehicleMultiplier(_ multiplier: Double, for vehicleSize: VehicleSize) {
        vehicleSizeMultipliers[vehicleSize] = multiplier
        updatedAt = Date()
    }
    
    mutating func addSpecialDiscount(_ discount: SpecialDiscount) {
        specialDiscounts.append(discount)
        updatedAt = Date()
    }
    
    mutating func updateBaseRates(baseFee: Int, baseMinutes: Int, unitFee: Int, unitMinutes: Int) {
        self.baseFee = baseFee
        self.baseMinutes = baseMinutes
        self.unitFee = unitFee
        self.unitMinutes = unitMinutes
        updatedAt = Date()
    }
    
    mutating func updateNightRates(flatFee: Int?, startHour: Int?, endHour: Int?) {
        self.nightFlatFee = flatFee
        self.nightStartHour = startHour
        self.nightEndHour = endHour
        updatedAt = Date()
    }
    
    mutating func updateMaxFees(maxFee: Int?, dailyMaxFee: Int?) {
        self.maxFee = maxFee
        self.dailyMaxFee = dailyMaxFee
        updatedAt = Date()
    }
}
