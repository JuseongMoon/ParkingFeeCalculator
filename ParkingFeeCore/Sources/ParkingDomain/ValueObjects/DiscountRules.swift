//
//  DiscountRules.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation

/// 할인 규칙 Value Object
public struct DiscountRules: Equatable, Hashable, Codable {
    public let driverDiscounts: DriverDiscountRules
    public let vehicleDiscounts: VehicleDiscountRules

    public init(
        driverDiscounts: DriverDiscountRules = DriverDiscountRules(),
        vehicleDiscounts: VehicleDiscountRules = VehicleDiscountRules()
    ) {
        self.driverDiscounts = driverDiscounts
        self.vehicleDiscounts = vehicleDiscounts
    }

    public var hasAnyDiscount: Bool {
        return driverDiscounts.hasAnyDiscount || vehicleDiscounts.hasAnyDiscount
    }
}

/// 운전자 관련 할인 규칙
public struct DriverDiscountRules: Equatable, Hashable, Codable {
    public let mildDisabilityDiscount: Double?
    public let severeDisabilityDiscount: Double?
    public let nationalMeritDiscount: Double?
    public let exemplaryTaxpayerDiscount: Double?
    public let multiChildDiscount: Double?
    public let seniorDiscount: Double?

    public init(
        mildDisabilityDiscount: Double? = nil,
        severeDisabilityDiscount: Double? = nil,
        nationalMeritDiscount: Double? = nil,
        exemplaryTaxpayerDiscount: Double? = nil,
        multiChildDiscount: Double? = nil,
        seniorDiscount: Double? = nil
    ) {
        self.mildDisabilityDiscount = mildDisabilityDiscount
        self.severeDisabilityDiscount = severeDisabilityDiscount
        self.nationalMeritDiscount = nationalMeritDiscount
        self.exemplaryTaxpayerDiscount = exemplaryTaxpayerDiscount
        self.multiChildDiscount = multiChildDiscount
        self.seniorDiscount = seniorDiscount
    }

    public var hasAnyDiscount: Bool {
        return mildDisabilityDiscount != nil ||
               severeDisabilityDiscount != nil ||
               nationalMeritDiscount != nil ||
               exemplaryTaxpayerDiscount != nil ||
               multiChildDiscount != nil ||
               seniorDiscount != nil
    }

    public func discountPercentage(for condition: SpecialCondition) -> Double? {
        switch condition {
        case .mildDisability: return mildDisabilityDiscount
        case .severeDisability: return severeDisabilityDiscount
        case .nationalMerit: return nationalMeritDiscount
        case .exemplaryTaxpayer: return exemplaryTaxpayerDiscount
        case .multiChild: return multiChildDiscount
        case .senior: return seniorDiscount
        }
    }
}

/// 차량 관련 할인 규칙
public struct VehicleDiscountRules: Equatable, Hashable, Codable {
    public let sizeDiscounts: VehicleSizeDiscounts
    public let fuelTypeDiscounts: FuelTypeDiscounts

    public init(
        sizeDiscounts: VehicleSizeDiscounts = VehicleSizeDiscounts(),
        fuelTypeDiscounts: FuelTypeDiscounts = FuelTypeDiscounts()
    ) {
        self.sizeDiscounts = sizeDiscounts
        self.fuelTypeDiscounts = fuelTypeDiscounts
    }

    public var hasAnyDiscount: Bool {
        return sizeDiscounts.hasAnyDiscount || fuelTypeDiscounts.hasAnyDiscount
    }
}

/// 차량 크기별 할인
public struct VehicleSizeDiscounts: Equatable, Hashable, Codable {
    public let lightCarDiscount: Double?
    public let normalCarDiscount: Double?
    public let largeCarDiscount: Double?

    public init(
        lightCarDiscount: Double? = nil,
        normalCarDiscount: Double? = nil,
        largeCarDiscount: Double? = nil
    ) {
        self.lightCarDiscount = lightCarDiscount
        self.normalCarDiscount = normalCarDiscount
        self.largeCarDiscount = largeCarDiscount
    }

    public var hasAnyDiscount: Bool {
        return lightCarDiscount != nil || normalCarDiscount != nil || largeCarDiscount != nil
    }

    public func discountPercentage(for size: VehicleSize) -> Double? {
        switch size {
        case .light: return lightCarDiscount
        case .normal: return normalCarDiscount
        case .large: return largeCarDiscount
        }
    }
}

/// 연료 타입별 할인 (친환경 차량)
public struct FuelTypeDiscounts: Equatable, Hashable, Codable {
    public let electricDiscount: Double?
    public let hydrogenDiscount: Double?
    public let hybridDiscount: Double?

    public init(
        electricDiscount: Double? = nil,
        hydrogenDiscount: Double? = nil,
        hybridDiscount: Double? = nil
    ) {
        self.electricDiscount = electricDiscount
        self.hydrogenDiscount = hydrogenDiscount
        self.hybridDiscount = hybridDiscount
    }

    public var hasAnyDiscount: Bool {
        return electricDiscount != nil || hydrogenDiscount != nil || hybridDiscount != nil
    }

    public func discountPercentage(for fuelType: VehicleFuelType) -> Double? {
        switch fuelType {
        case .electric: return electricDiscount
        case .hydrogen: return hydrogenDiscount
        case .hybrid: return hybridDiscount
        case .gasoline, .diesel: return nil
        }
    }
}

/// 할인 정보 결과
public struct DiscountInfo: Equatable, Hashable {
    public let name: String
    public let percentage: Double
    public let type: DiscountType

    public init(name: String, percentage: Double, type: DiscountType) {
        self.name = name
        self.percentage = percentage
        self.type = type
    }
}

/// 할인 타입
public enum DiscountType: Equatable, Hashable {
    case driver
    case vehicleSize
    case vehicleFuel
}

/// 주차비 계산 결과
public struct FeeCalculationResult: Equatable {
    public let baseFee: Int
    public let discountedFee: Int
    public let appliedDiscounts: [DiscountInfo]
    public let totalDiscountAmount: Int
    public let totalDiscountPercentage: Double

    public init(
        baseFee: Int,
        discountedFee: Int,
        appliedDiscounts: [DiscountInfo]
    ) {
        self.baseFee = baseFee
        self.discountedFee = discountedFee
        self.appliedDiscounts = appliedDiscounts
        self.totalDiscountAmount = baseFee - discountedFee
        self.totalDiscountPercentage = baseFee > 0 ? Double(totalDiscountAmount) / Double(baseFee) * 100.0 : 0.0
    }

    public var finalFee: Int { discountedFee }
}