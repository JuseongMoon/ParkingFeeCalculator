//
//  CalculateParkingFeeUseCaseImpl.swift
//  ParkingUI
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine
import ParkingDomain

/// 주차비 계산 Use Case 구현체
public final class CalculateParkingFeeUseCaseImpl: CalculateParkingFeeUseCase {

    public init() {}

    // MARK: - CalculateParkingFeeUseCase Implementation

    public func calculateFee(
        for parkingLot: ParkingLotEntity,
        vehicle: VehicleProfile,
        driver: DriverProfile,
        duration: TimeInterval,
        startTime: Date = Date(),
        additionalFreeMinutes: Int = 0
    ) -> AnyPublisher<FeeCalculationResult, Error> {
        return Future { promise in
            do {
                let result = try self.performFeeCalculation(
                    parkingLot: parkingLot,
                    vehicle: vehicle,
                    driver: driver,
                    duration: duration,
                    startTime: startTime,
                    additionalFreeMinutes: additionalFreeMinutes
                )
                promise(.success(result))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

    public func calculateCurrentSessionFee(_ session: ParkingSessionEntity) -> AnyPublisher<FeeCalculationResult, Error> {
        let currentTime = Date()
        let duration = currentTime.timeIntervalSince(session.startTime)

        return calculateFee(
            for: session.parkingLot,
            vehicle: session.vehicle,
            driver: session.driver,
            duration: duration,
            startTime: session.startTime,
            additionalFreeMinutes: session.additionalFreeMinutes
        )
    }

    public func estimateFee(
        for session: ParkingSessionEntity,
        afterMinutes: Int
    ) -> AnyPublisher<FeeCalculationResult, Error> {
        let currentTime = Date()
        let estimatedDuration = currentTime.timeIntervalSince(session.startTime) + TimeInterval(afterMinutes * 60)

        return calculateFee(
            for: session.parkingLot,
            vehicle: session.vehicle,
            driver: session.driver,
            duration: estimatedDuration,
            startTime: session.startTime,
            additionalFreeMinutes: session.additionalFreeMinutes
        )
    }

    public func getApplicableDiscounts(
        for parkingLot: ParkingLotEntity,
        vehicle: VehicleProfile,
        driver: DriverProfile
    ) -> AnyPublisher<[DiscountInfo], Error> {
        return Future { promise in
            let discounts = self.findApplicableDiscounts(
                parkingLot: parkingLot,
                vehicle: vehicle,
                driver: driver
            )
            promise(.success(discounts))
        }.eraseToAnyPublisher()
    }

    // MARK: - Private Implementation

    private func performFeeCalculation(
        parkingLot: ParkingLotEntity,
        vehicle: VehicleProfile,
        driver: DriverProfile,
        duration: TimeInterval,
        startTime: Date,
        additionalFreeMinutes: Int
    ) throws -> FeeCalculationResult {
        let rules = parkingLot.feeCalculationRules

        // 1. 기본 요금 계산
        let baseFee = try calculateBaseFee(
            rules: rules,
            duration: duration,
            startTime: startTime,
            additionalFreeMinutes: additionalFreeMinutes
        )

        // 2. 할인 적용
        let applicableDiscounts = findApplicableDiscounts(
            parkingLot: parkingLot,
            vehicle: vehicle,
            driver: driver
        )

        // 3. 최적 할인 선택 (가장 높은 할인율)
        let bestDiscount = applicableDiscounts.max { $0.percentage < $1.percentage }

        // 4. 할인 적용된 최종 요금 계산
        var finalFee = baseFee
        var appliedDiscounts: [DiscountInfo] = []

        if let discount = bestDiscount {
            finalFee = Int(round(Double(baseFee) * (1.0 - discount.percentage / 100.0)))
            appliedDiscounts = [discount]
        }

        // 5. 최대 요금 제한 적용
        if let maxFeeRules = rules.maxFeeRules {
            if let maxFee = maxFeeRules.maxFee {
                finalFee = min(finalFee, maxFee)
            }
            if let dailyMaxFee = maxFeeRules.dailyMaxFee {
                finalFee = min(finalFee, dailyMaxFee)
            }
        }

        return FeeCalculationResult(
            baseFee: baseFee,
            discountedFee: finalFee,
            appliedDiscounts: appliedDiscounts
        )
    }

    private func calculateBaseFee(
        rules: FeeCalculationRules,
        duration: TimeInterval,
        startTime: Date,
        additionalFreeMinutes: Int
    ) throws -> Int {
        // 총 무료 시간 계산
        let totalFreeMinutes = rules.basicRules.freeMinutes + additionalFreeMinutes
        let totalFreeSeconds = TimeInterval(totalFreeMinutes * 60)

        // 무료 시간 체크
        if duration <= totalFreeSeconds {
            return 0
        }

        // 과금 시간 계산
        let chargeableDuration = duration - totalFreeSeconds
        let chargeableMinutes = Int(ceil(chargeableDuration / 60))

        // 야간 요금 체크
        if let nightRules = rules.nightRules, nightRules.isNightTime(at: startTime) {
            return calculateNightFee(nightRules: nightRules, basicRules: rules.basicRules, chargeableMinutes: chargeableMinutes)
        }

        // 시간대별 차등 요금 체크
        if let timeBasedRules = rules.timeBasedRules, timeBasedRules.isEnabled {
            return calculateTimeBasedFee(timeBasedRules: timeBasedRules, basicRules: rules.basicRules, chargeableMinutes: chargeableMinutes)
        }

        // 기본 요금 계산
        return calculateSimpleFee(basicRules: rules.basicRules, chargeableMinutes: chargeableMinutes)
    }

    private func calculateSimpleFee(basicRules: BasicFeeRules, chargeableMinutes: Int) -> Int {
        if chargeableMinutes <= basicRules.initialMinutes {
            return basicRules.initialFee
        }

        let extraMinutes = chargeableMinutes - basicRules.initialMinutes
        let additionalUnits = Int(ceil(Double(extraMinutes) / Double(basicRules.additionalMinutes)))
        let extraFee = additionalUnits * basicRules.additionalFee

        return basicRules.initialFee + extraFee
    }

    private func calculateNightFee(nightRules: NightRateRules, basicRules: BasicFeeRules, chargeableMinutes: Int) -> Int {
        switch nightRules.type {
        case .flat:
            return nightRules.flatFee ?? calculateSimpleFee(basicRules: basicRules, chargeableMinutes: chargeableMinutes)
        case .percentage:
            let normalFee = calculateSimpleFee(basicRules: basicRules, chargeableMinutes: chargeableMinutes)
            guard let discountPercentage = nightRules.discountPercentage else {
                return normalFee
            }
            return Int(round(Double(normalFee) * (1.0 - discountPercentage / 100.0)))
        }
    }

    private func calculateTimeBasedFee(timeBasedRules: TimeBasedPricingRules, basicRules: BasicFeeRules, chargeableMinutes: Int) -> Int {
        var totalFee = 0
        var remainingMinutes = chargeableMinutes

        // 초기 요금 적용
        if remainingMinutes > 0 {
            let initialUnits = min(remainingMinutes, basicRules.initialMinutes)
            if initialUnits > 0 {
                totalFee = basicRules.initialFee
                remainingMinutes -= basicRules.initialMinutes
            }
        }

        if remainingMinutes <= 0 {
            return totalFee
        }

        // 시간대별 요금 적용
        let sortedTiers = timeBasedRules.tiers
        var currentThreshold = basicRules.initialMinutes

        for tier in sortedTiers {
            if remainingMinutes <= 0 { break }

            // 현재 구간까지는 기본 추가 요금 적용
            if currentThreshold < tier.thresholdMinutes {
                let minutesToProcess = min(remainingMinutes, tier.thresholdMinutes - currentThreshold)
                if minutesToProcess > 0 {
                    let units = Int(ceil(Double(minutesToProcess) / Double(basicRules.additionalMinutes)))
                    totalFee += units * basicRules.additionalFee
                    remainingMinutes -= minutesToProcess
                }
                currentThreshold = tier.thresholdMinutes
            }

            // 해당 tier의 요금 적용
            if remainingMinutes > 0 {
                let nextThreshold = sortedTiers.first(where: { $0.thresholdMinutes > tier.thresholdMinutes })?.thresholdMinutes ?? Int.max
                let tierMinutes = min(remainingMinutes, nextThreshold - tier.thresholdMinutes)

                if tierMinutes > 0 {
                    let units = Int(ceil(Double(tierMinutes) / Double(tier.unitMinutes)))
                    totalFee += units * tier.feePerUnit
                    remainingMinutes -= tierMinutes
                    currentThreshold = tier.thresholdMinutes + tierMinutes
                }
            }
        }

        // 마지막 tier 이후 남은 시간 처리
        if remainingMinutes > 0, let lastTier = sortedTiers.last {
            let units = Int(ceil(Double(remainingMinutes) / Double(lastTier.unitMinutes)))
            totalFee += units * lastTier.feePerUnit
        }

        return totalFee
    }

    private func findApplicableDiscounts(
        parkingLot: ParkingLotEntity,
        vehicle: VehicleProfile,
        driver: DriverProfile
    ) -> [DiscountInfo] {
        var discounts: [DiscountInfo] = []
        let discountRules = parkingLot.discountRules

        // 운전자 관련 할인
        for condition in driver.specialConditions {
            if let percentage = discountRules.driverDiscounts.discountPercentage(for: condition) {
                discounts.append(DiscountInfo(
                    name: condition.displayName,
                    percentage: percentage,
                    type: .driver
                ))
            }
        }

        // 차량 크기별 할인
        if let sizeDiscount = discountRules.vehicleDiscounts.sizeDiscounts.discountPercentage(for: vehicle.size) {
            discounts.append(DiscountInfo(
                name: vehicle.size.displayName,
                percentage: sizeDiscount,
                type: .vehicleSize
            ))
        }

        // 연료 타입별 할인
        if let fuelDiscount = discountRules.vehicleDiscounts.fuelTypeDiscounts.discountPercentage(for: vehicle.fuelType) {
            discounts.append(DiscountInfo(
                name: vehicle.fuelType.displayName,
                percentage: fuelDiscount,
                type: .vehicleFuel
            ))
        }

        return discounts
    }
}