//
//  ManageParkingSessionUseCase.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine

/// 주차 세션 관리 Use Case 인터페이스
public protocol ManageParkingSessionUseCase {
    /// 새 주차 세션을 시작합니다
    func startSession(
        parkingLot: ParkingLotEntity,
        vehicle: VehicleProfile,
        driver: DriverProfile,
        additionalFreeMinutes: Int
    ) -> AnyPublisher<ParkingSessionEntity, Error>

    /// 현재 활성 세션을 가져옵니다
    func getCurrentSession() -> AnyPublisher<ParkingSessionEntity?, Error>

    /// 세션을 종료합니다
    func endSession() -> AnyPublisher<ParkingSessionEntity?, Error>

    /// 세션의 추가 무료시간을 업데이트합니다
    func updateAdditionalFreeMinutes(_ minutes: Int) -> AnyPublisher<ParkingSessionEntity?, Error>

    /// 세션이 활성 상태인지 확인합니다
    func isSessionActive() -> AnyPublisher<Bool, Error>

    /// 현재 세션을 관찰합니다 (실시간 업데이트)
    var currentSessionPublisher: AnyPublisher<ParkingSessionEntity?, Error> { get }

    /// 세션 상태 변경을 관찰합니다
    var sessionStatePublisher: AnyPublisher<SessionState, Error> { get }
}

/// 세션 상태
public enum SessionState: Equatable {
    case idle
    case active(ParkingSessionEntity)
    case ended(ParkingSessionEntity)
}