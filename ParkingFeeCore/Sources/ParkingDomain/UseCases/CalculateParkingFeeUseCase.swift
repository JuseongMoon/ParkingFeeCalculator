//
//  CalculateParkingFeeUseCase.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine

/// 주차비 계산 Use Case 인터페이스
public protocol CalculateParkingFeeUseCase {
    /// 주차비를 계산합니다
    func calculateFee(
        for parkingLot: ParkingLotEntity,
        vehicle: VehicleProfile,
        driver: DriverProfile,
        duration: TimeInterval,
        startTime: Date,
        additionalFreeMinutes: Int
    ) -> AnyPublisher<FeeCalculationResult, Error>

    /// 현재 세션의 실시간 주차비를 계산합니다
    func calculateCurrentSessionFee(_ session: ParkingSessionEntity) -> AnyPublisher<FeeCalculationResult, Error>

    /// 예상 주차비를 계산합니다 (특정 시간 후)
    func estimateFee(
        for session: ParkingSessionEntity,
        afterMinutes: Int
    ) -> AnyPublisher<FeeCalculationResult, Error>

    /// 적용 가능한 모든 할인을 확인합니다
    func getApplicableDiscounts(
        for parkingLot: ParkingLotEntity,
        vehicle: VehicleProfile,
        driver: DriverProfile
    ) -> AnyPublisher<[DiscountInfo], Error>
}