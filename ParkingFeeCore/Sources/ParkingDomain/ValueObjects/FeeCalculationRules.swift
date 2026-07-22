//
//  FeeCalculationRules.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation

/// 주차비 계산 규칙 Value Object
public struct FeeCalculationRules: Equatable, Hashable, Codable {
    public let basicRules: BasicFeeRules
    public let nightRules: NightRateRules?
    public let maxFeeRules: MaxFeeRules?
    public let timeBasedRules: TimeBasedPricingRules?

    public init(
        basicRules: BasicFeeRules,
        nightRules: NightRateRules? = nil,
        maxFeeRules: MaxFeeRules? = nil,
        timeBasedRules: TimeBasedPricingRules? = nil
    ) {
        self.basicRules = basicRules
        self.nightRules = nightRules
        self.maxFeeRules = maxFeeRules
        self.timeBasedRules = timeBasedRules
    }
}

/// 기본 요금 규칙
public struct BasicFeeRules: Equatable, Hashable, Codable {
    public let initialFee: Int
    public let initialMinutes: Int
    public let additionalFee: Int
    public let additionalMinutes: Int
    public let freeMinutes: Int

    public init(
        initialFee: Int,
        initialMinutes: Int,
        additionalFee: Int,
        additionalMinutes: Int,
        freeMinutes: Int = 0
    ) {
        self.initialFee = initialFee
        self.initialMinutes = initialMinutes
        self.additionalFee = additionalFee
        self.additionalMinutes = additionalMinutes
        self.freeMinutes = freeMinutes
    }
}

/// 야간 요금 규칙
public struct NightRateRules: Equatable, Hashable, Codable {
    public let type: NightRateType
    public let startHour: Int
    public let endHour: Int
    public let flatFee: Int?
    public let discountPercentage: Double?

    public init(
        type: NightRateType,
        startHour: Int,
        endHour: Int,
        flatFee: Int? = nil,
        discountPercentage: Double? = nil
    ) {
        self.type = type
        self.startHour = startHour
        self.endHour = endHour
        self.flatFee = flatFee
        self.discountPercentage = discountPercentage
    }

    public func isNightTime(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)

        if startHour <= endHour {
            return currentHour >= startHour && currentHour < endHour
        } else {
            // 자정을 넘어가는 경우 (예: 22시~06시)
            return currentHour >= startHour || currentHour < endHour
        }
    }
}

/// 야간 요금 타입
public enum NightRateType: String, CaseIterable, Codable {
    case flat = "flat"
    case percentage = "percentage"

    public var displayName: String {
        switch self {
        case .flat: return "정액 요금"
        case .percentage: return "할인율 적용"
        }
    }
}

/// 최대 요금 제한 규칙
public struct MaxFeeRules: Equatable, Hashable, Codable {
    public let maxFee: Int?
    public let dailyMaxFee: Int?

    public init(maxFee: Int? = nil, dailyMaxFee: Int? = nil) {
        self.maxFee = maxFee
        self.dailyMaxFee = dailyMaxFee
    }
}

/// 시간 구간별 차등 요금 규칙
public struct TimeBasedPricingRules: Equatable, Hashable, Codable {
    public let tiers: [PricingTier]

    public init(tiers: [PricingTier]) {
        self.tiers = tiers.sorted { $0.thresholdMinutes < $1.thresholdMinutes }
    }

    public var isEnabled: Bool {
        return !tiers.isEmpty
    }
}

/// 요금 구간
public struct PricingTier: Identifiable, Equatable, Hashable, Codable {
    public let id: UUID
    public let thresholdMinutes: Int
    public let feePerUnit: Int
    public let unitMinutes: Int

    public init(
        id: UUID = UUID(),
        thresholdMinutes: Int,
        feePerUnit: Int,
        unitMinutes: Int
    ) {
        self.id = id
        self.thresholdMinutes = thresholdMinutes
        self.feePerUnit = feePerUnit
        self.unitMinutes = unitMinutes
    }
}