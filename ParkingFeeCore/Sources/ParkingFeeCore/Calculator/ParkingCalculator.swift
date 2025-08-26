//
//  ParkingCalculator.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/26/25.
//

import Foundation

/// 주차 요금 계산을 위한 메인 계산기
public final class ParkingCalculator {
    public static let shared = ParkingCalculator()
    
    private init() {}
    
    /// 주차 요금 계산 (기존 ParkingFeeCalculator 로직 사용)
    public func calculate(
        duration: TimeInterval,
        using calculator: ParkingFeeCalculator,
        vehicleProfile: VehicleProfile,
        driverProfile: DriverProfile,
        specialConditionDiscounts: SpecialConditionDiscounts,
        startTime: Date = Date(),
        additionalFreeMinutes: Int = 0
    ) -> ParkingFeeResult {
        return calculator.calculateFee(
            duration: duration,
            vehicleProfile: vehicleProfile,
            driverProfile: driverProfile,
            specialConditionDiscounts: specialConditionDiscounts,
            startTime: startTime,
            additionalFreeMinutes: additionalFreeMinutes
        )
    }
}