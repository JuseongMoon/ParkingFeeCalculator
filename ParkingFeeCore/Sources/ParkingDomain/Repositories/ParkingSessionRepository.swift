//
//  ParkingSessionRepository.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine

/// 주차 세션 데이터 저장소 인터페이스
public protocol ParkingSessionRepository {
    /// 현재 활성 세션을 가져옵니다
    func getCurrentSession() -> AnyPublisher<ParkingSessionEntity?, Error>

    /// 세션을 저장합니다
    func saveSession(_ session: ParkingSessionEntity) -> AnyPublisher<ParkingSessionEntity, Error>

    /// 세션을 삭제합니다 (종료)
    func clearCurrentSession() -> AnyPublisher<Void, Error>

    /// 세션 상태 변경을 관찰합니다
    var sessionPublisher: AnyPublisher<ParkingSessionEntity?, Error> { get }

    /// 세션이 활성 상태인지 확인합니다
    func isSessionActive() -> AnyPublisher<Bool, Error>
}