//
//  FeeCalculationService.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/24/25.
//

import Foundation

/// 중앙화된 주차비 계산 서비스
public final class FeeCalculationService {
    public static let shared = FeeCalculationService()
    
    private init() {}
    
    /// 주차 세션에 대한 현재 주차비를 계산합니다
    /// - Parameter session: 주차 세션 정보
    /// - Parameter at: 계산할 시점 (기본값: 현재 시간)
    /// - Returns: 계산된 주차비 결과
    public func calculateFee(
        for session: SharedParkingSession,
        at date: Date = Date()
    ) -> ParkingFeeResult {
        let elapsed = date.timeIntervalSince(session.startTime)
        
        return session.parkingLot.parkingFeeCalculator.calculateFee(
            duration: elapsed,
            vehicleProfile: session.vehicle,
            driverProfile: session.driver,
            specialConditionDiscounts: session.parkingLot.specialConditionDiscounts,
            startTime: session.startTime,
            additionalFreeMinutes: session.additionalFreeMinutes
        )
    }
    
    /// 특정 시간대의 주차비를 계산합니다
    /// - Parameters:
    ///   - parkingLot: 주차장 프로필
    ///   - vehicle: 차량 프로필
    ///   - driver: 운전자 프로필
    ///   - duration: 주차 시간 (초)
    ///   - startTime: 주차 시작 시간
    ///   - additionalFreeMinutes: 추가 무료시간
    /// - Returns: 계산된 주차비 결과
    public func calculateFee(
        parkingLot: ParkingLotProfile,
        vehicle: VehicleProfile,
        driver: DriverProfile,
        duration: TimeInterval,
        startTime: Date = Date(),
        additionalFreeMinutes: Int = 0
    ) -> ParkingFeeResult {
        return parkingLot.parkingFeeCalculator.calculateFee(
            duration: duration,
            vehicleProfile: vehicle,
            driverProfile: driver,
            specialConditionDiscounts: parkingLot.specialConditionDiscounts,
            startTime: startTime,
            additionalFreeMinutes: additionalFreeMinutes
        )
    }
    
    /// 예상 주차비를 계산합니다 (특정 시간 후 예상 요금)
    /// - Parameters:
    ///   - session: 현재 주차 세션
    ///   - afterMinutes: 추가 주차 예상 시간 (분)
    /// - Returns: 예상 주차비 결과
    public func estimateFee(
        for session: SharedParkingSession,
        afterMinutes: Int
    ) -> ParkingFeeResult {
        let currentElapsed = Date().timeIntervalSince(session.startTime)
        let estimatedElapsed = currentElapsed + TimeInterval(afterMinutes * 60)
        
        return session.parkingLot.parkingFeeCalculator.calculateFee(
            duration: estimatedElapsed,
            vehicleProfile: session.vehicle,
            driverProfile: session.driver,
            specialConditionDiscounts: session.parkingLot.specialConditionDiscounts,
            startTime: session.startTime,
            additionalFreeMinutes: session.additionalFreeMinutes
        )
    }
}