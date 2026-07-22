//
//  EntityMapper.swift
//  ParkingData
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import ParkingDomain

/// Domain 엔티티와 Data 모델 간 변환을 담당하는 매퍼
public enum EntityMapper {

    // MARK: - Legacy Compatibility Models

    /// Legacy ParkingLotProfile (기존 모델과 호환)
    struct LegacyParkingLotProfile: Codable {
        let id: UUID
        let name: String
        let address: String
        let parkingFeeCalculator: LegacyParkingFeeCalculator
        let specialConditionDiscounts: LegacySpecialConditionDiscounts
        let createdAt: Date
        let updatedAt: Date
    }

    /// Legacy ParkingFeeCalculator
    struct LegacyParkingFeeCalculator: Codable {
        let id: UUID
        let initialFee: Int
        let initialMinutes: Int
        let additionalFee: Int
        let additionalMinutes: Int
        let maxFee: Int?
        let freeMinutes: Int
        let dailyMaxFee: Int?
        let nightFlatFee: Int?
        let nightStartHour: Int?
        let nightEndHour: Int?
        let nightRateType: String // "flat" or "percentage"
        let nightDiscountPercentage: Double?
        let useTimeBasedPricing: Bool
        let pricingTiers: [LegacyPricingTier]
        let createdAt: Date
        let updatedAt: Date
    }

    /// Legacy PricingTier
    struct LegacyPricingTier: Codable {
        let id: UUID
        let thresholdMinutes: Int
        let feePerUnit: Int
        let unitMinutes: Int
    }

    /// Legacy SpecialConditionDiscounts
    struct LegacySpecialConditionDiscounts: Codable {
        let mildDiscountPercentage: Double?
        let severeDiscountPercentage: Double?
        let nationalMeritDiscountPercentage: Double?
        let exemplaryTaxpayerDiscountPercentage: Double?
        let multiChildDiscountPercentage: Double?
        let seniorDiscountPercentage: Double?
        let lightCarDiscountPercentage: Double?
        let normalCarDiscountPercentage: Double?
        let largeCarDiscountPercentage: Double?
        let electricDiscountPercentage: Double?
        let hydrogenDiscountPercentage: Double?
        let hybridDiscountPercentage: Double?
    }

    /// Legacy VehicleProfile
    struct LegacyVehicleProfile: Codable {
        let id: UUID
        let vehicleSize: String // "light", "normal", "large"
        let isElectric: Bool
        let isHydrogen: Bool
        let isHybrid: Bool
        let createdAt: Date
        let updatedAt: Date
    }

    /// Legacy DriverProfile
    struct LegacyDriverProfile: Codable {
        let id: UUID
        let isDisabled: Bool
        let disabilityLevel: String? // "mild", "severe"
        let isNationalMerit: Bool
        let isExemplaryTaxpayer: Bool
        let isMultiChild: Bool
        let isSenior: Bool
        let createdAt: Date
        let updatedAt: Date
    }
}

// MARK: - ParkingLot Mapping

extension EntityMapper {
    /// Legacy ParkingLotProfile을 ParkingLotEntity로 변환
    static func toDomain(_ legacy: LegacyParkingLotProfile) -> ParkingLotEntity {
        let feeRules = FeeCalculationRules(
            basicRules: BasicFeeRules(
                initialFee: legacy.parkingFeeCalculator.initialFee,
                initialMinutes: legacy.parkingFeeCalculator.initialMinutes,
                additionalFee: legacy.parkingFeeCalculator.additionalFee,
                additionalMinutes: legacy.parkingFeeCalculator.additionalMinutes,
                freeMinutes: legacy.parkingFeeCalculator.freeMinutes
            ),
            nightRules: mapNightRules(legacy.parkingFeeCalculator),
            maxFeeRules: MaxFeeRules(
                maxFee: legacy.parkingFeeCalculator.maxFee,
                dailyMaxFee: legacy.parkingFeeCalculator.dailyMaxFee
            ),
            timeBasedRules: mapTimeBasedRules(legacy.parkingFeeCalculator)
        )

        let discountRules = DiscountRules(
            driverDiscounts: mapDriverDiscounts(legacy.specialConditionDiscounts),
            vehicleDiscounts: mapVehicleDiscounts(legacy.specialConditionDiscounts)
        )

        return ParkingLotEntity(
            id: legacy.id,
            name: legacy.name,
            address: legacy.address,
            feeCalculationRules: feeRules,
            discountRules: discountRules,
            createdAt: legacy.createdAt,
            updatedAt: legacy.updatedAt
        )
    }

    /// ParkingLotEntity를 Legacy ParkingLotProfile로 변환
    static func toLegacy(_ domain: ParkingLotEntity) -> LegacyParkingLotProfile {
        let legacyCalculator = LegacyParkingFeeCalculator(
            id: UUID(),
            initialFee: domain.feeCalculationRules.basicRules.initialFee,
            initialMinutes: domain.feeCalculationRules.basicRules.initialMinutes,
            additionalFee: domain.feeCalculationRules.basicRules.additionalFee,
            additionalMinutes: domain.feeCalculationRules.basicRules.additionalMinutes,
            maxFee: domain.feeCalculationRules.maxFeeRules?.maxFee,
            freeMinutes: domain.feeCalculationRules.basicRules.freeMinutes,
            dailyMaxFee: domain.feeCalculationRules.maxFeeRules?.dailyMaxFee,
            nightFlatFee: domain.feeCalculationRules.nightRules?.flatFee,
            nightStartHour: domain.feeCalculationRules.nightRules?.startHour,
            nightEndHour: domain.feeCalculationRules.nightRules?.endHour,
            nightRateType: domain.feeCalculationRules.nightRules?.type.rawValue ?? "flat",
            nightDiscountPercentage: domain.feeCalculationRules.nightRules?.discountPercentage,
            useTimeBasedPricing: domain.feeCalculationRules.timeBasedRules?.isEnabled ?? false,
            pricingTiers: domain.feeCalculationRules.timeBasedRules?.tiers.map { tier in
                LegacyPricingTier(
                    id: tier.id,
                    thresholdMinutes: tier.thresholdMinutes,
                    feePerUnit: tier.feePerUnit,
                    unitMinutes: tier.unitMinutes
                )
            } ?? [],
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )

        let legacyDiscounts = LegacySpecialConditionDiscounts(
            mildDiscountPercentage: domain.discountRules.driverDiscounts.mildDisabilityDiscount,
            severeDiscountPercentage: domain.discountRules.driverDiscounts.severeDisabilityDiscount,
            nationalMeritDiscountPercentage: domain.discountRules.driverDiscounts.nationalMeritDiscount,
            exemplaryTaxpayerDiscountPercentage: domain.discountRules.driverDiscounts.exemplaryTaxpayerDiscount,
            multiChildDiscountPercentage: domain.discountRules.driverDiscounts.multiChildDiscount,
            seniorDiscountPercentage: domain.discountRules.driverDiscounts.seniorDiscount,
            lightCarDiscountPercentage: domain.discountRules.vehicleDiscounts.sizeDiscounts.lightCarDiscount,
            normalCarDiscountPercentage: domain.discountRules.vehicleDiscounts.sizeDiscounts.normalCarDiscount,
            largeCarDiscountPercentage: domain.discountRules.vehicleDiscounts.sizeDiscounts.largeCarDiscount,
            electricDiscountPercentage: domain.discountRules.vehicleDiscounts.fuelTypeDiscounts.electricDiscount,
            hydrogenDiscountPercentage: domain.discountRules.vehicleDiscounts.fuelTypeDiscounts.hydrogenDiscount,
            hybridDiscountPercentage: domain.discountRules.vehicleDiscounts.fuelTypeDiscounts.hybridDiscount
        )

        return LegacyParkingLotProfile(
            id: domain.id,
            name: domain.name,
            address: domain.address,
            parkingFeeCalculator: legacyCalculator,
            specialConditionDiscounts: legacyDiscounts,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }

    // MARK: - Helper Methods

    private static func mapNightRules(_ legacy: LegacyParkingFeeCalculator) -> NightRateRules? {
        guard let startHour = legacy.nightStartHour,
              let endHour = legacy.nightEndHour else {
            return nil
        }

        let type: NightRateType = legacy.nightRateType == "percentage" ? .percentage : .flat

        return NightRateRules(
            type: type,
            startHour: startHour,
            endHour: endHour,
            flatFee: legacy.nightFlatFee,
            discountPercentage: legacy.nightDiscountPercentage
        )
    }

    private static func mapTimeBasedRules(_ legacy: LegacyParkingFeeCalculator) -> TimeBasedPricingRules? {
        guard legacy.useTimeBasedPricing && !legacy.pricingTiers.isEmpty else {
            return nil
        }

        let tiers = legacy.pricingTiers.map { legacyTier in
            PricingTier(
                id: legacyTier.id,
                thresholdMinutes: legacyTier.thresholdMinutes,
                feePerUnit: legacyTier.feePerUnit,
                unitMinutes: legacyTier.unitMinutes
            )
        }

        return TimeBasedPricingRules(tiers: tiers)
    }

    private static func mapDriverDiscounts(_ legacy: LegacySpecialConditionDiscounts) -> DriverDiscountRules {
        return DriverDiscountRules(
            mildDisabilityDiscount: legacy.mildDiscountPercentage,
            severeDisabilityDiscount: legacy.severeDiscountPercentage,
            nationalMeritDiscount: legacy.nationalMeritDiscountPercentage,
            exemplaryTaxpayerDiscount: legacy.exemplaryTaxpayerDiscountPercentage,
            multiChildDiscount: legacy.multiChildDiscountPercentage,
            seniorDiscount: legacy.seniorDiscountPercentage
        )
    }

    private static func mapVehicleDiscounts(_ legacy: LegacySpecialConditionDiscounts) -> VehicleDiscountRules {
        let sizeDiscounts = VehicleSizeDiscounts(
            lightCarDiscount: legacy.lightCarDiscountPercentage,
            normalCarDiscount: legacy.normalCarDiscountPercentage,
            largeCarDiscount: legacy.largeCarDiscountPercentage
        )

        let fuelDiscounts = FuelTypeDiscounts(
            electricDiscount: legacy.electricDiscountPercentage,
            hydrogenDiscount: legacy.hydrogenDiscountPercentage,
            hybridDiscount: legacy.hybridDiscountPercentage
        )

        return VehicleDiscountRules(
            sizeDiscounts: sizeDiscounts,
            fuelTypeDiscounts: fuelDiscounts
        )
    }
}

// MARK: - Profile Mapping

extension EntityMapper {
    /// Legacy VehicleProfile을 Domain VehicleProfile로 변환
    static func toDomain(_ legacy: LegacyVehicleProfile) -> VehicleProfile {
        let size: VehicleSize
        switch legacy.vehicleSize {
        case "light": size = .light
        case "large": size = .large
        default: size = .normal
        }

        let fuelType: VehicleFuelType
        if legacy.isElectric {
            fuelType = .electric
        } else if legacy.isHydrogen {
            fuelType = .hydrogen
        } else if legacy.isHybrid {
            fuelType = .hybrid
        } else {
            fuelType = .gasoline
        }

        return VehicleProfile(size: size, fuelType: fuelType)
    }

    /// Domain VehicleProfile을 Legacy VehicleProfile로 변환
    static func toLegacy(_ domain: VehicleProfile) -> LegacyVehicleProfile {
        return LegacyVehicleProfile(
            id: UUID(),
            vehicleSize: domain.size.rawValue,
            isElectric: domain.fuelType == .electric,
            isHydrogen: domain.fuelType == .hydrogen,
            isHybrid: domain.fuelType == .hybrid,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Legacy DriverProfile을 Domain DriverProfile로 변환
    static func toDomain(_ legacy: LegacyDriverProfile) -> DriverProfile {
        var conditions: Set<SpecialCondition> = []

        if legacy.isDisabled {
            if let level = legacy.disabilityLevel {
                switch level {
                case "mild":
                    conditions.insert(.mildDisability)
                case "severe":
                    conditions.insert(.severeDisability)
                default:
                    conditions.insert(.mildDisability)
                }
            }
        }

        if legacy.isNationalMerit {
            conditions.insert(.nationalMerit)
        }

        if legacy.isExemplaryTaxpayer {
            conditions.insert(.exemplaryTaxpayer)
        }

        if legacy.isMultiChild {
            conditions.insert(.multiChild)
        }

        if legacy.isSenior {
            conditions.insert(.senior)
        }

        return DriverProfile(specialConditions: conditions)
    }

    /// Domain DriverProfile을 Legacy DriverProfile로 변환
    static func toLegacy(_ domain: DriverProfile) -> LegacyDriverProfile {
        let isDisabled = domain.specialConditions.contains(.mildDisability) ||
                        domain.specialConditions.contains(.severeDisability)

        let disabilityLevel: String?
        if domain.specialConditions.contains(.severeDisability) {
            disabilityLevel = "severe"
        } else if domain.specialConditions.contains(.mildDisability) {
            disabilityLevel = "mild"
        } else {
            disabilityLevel = nil
        }

        return LegacyDriverProfile(
            id: UUID(),
            isDisabled: isDisabled,
            disabilityLevel: disabilityLevel,
            isNationalMerit: domain.specialConditions.contains(.nationalMerit),
            isExemplaryTaxpayer: domain.specialConditions.contains(.exemplaryTaxpayer),
            isMultiChild: domain.specialConditions.contains(.multiChild),
            isSenior: domain.specialConditions.contains(.senior),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}