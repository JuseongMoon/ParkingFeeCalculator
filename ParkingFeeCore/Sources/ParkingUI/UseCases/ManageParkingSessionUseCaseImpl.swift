//
//  ManageParkingSessionUseCaseImpl.swift
//  ParkingUI
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine
import ParkingDomain

/// 주차 세션 관리 Use Case 구현체
public final class ManageParkingSessionUseCaseImpl: ManageParkingSessionUseCase {
    private let sessionRepository: ParkingSessionRepository
    private let sessionStateSubject = CurrentValueSubject<SessionState, Error>(.idle)

    public init(sessionRepository: ParkingSessionRepository) {
        self.sessionRepository = sessionRepository
        observeSessionChanges()
    }

    // MARK: - ManageParkingSessionUseCase Implementation

    public func startSession(
        parkingLot: ParkingLotEntity,
        vehicle: VehicleProfile,
        driver: DriverProfile,
        additionalFreeMinutes: Int = 0
    ) -> AnyPublisher<ParkingSessionEntity, Error> {
        // 기존 세션 확인
        return sessionRepository.getCurrentSession()
            .flatMap { [weak self] existingSession -> AnyPublisher<ParkingSessionEntity, Error> in
                guard let self = self else {
                    return Fail(error: DomainError.sessionAlreadyExists)
                        .eraseToAnyPublisher()
                }

                if let existing = existingSession, existing.isActive {
                    return Fail(error: DomainError.sessionAlreadyExists)
                        .eraseToAnyPublisher()
                }

                // 새 세션 생성
                let newSession = ParkingSessionEntity(
                    startTime: Date(),
                    parkingLot: parkingLot,
                    vehicle: vehicle,
                    driver: driver,
                    additionalFreeMinutes: additionalFreeMinutes,
                    status: .active
                )

                return self.sessionRepository.saveSession(newSession)
                    .handleEvents(receiveOutput: { session in
                        self.sessionStateSubject.send(.active(session))
                        print("🚀 [ManageParkingSessionUseCase] 새 주차 세션 시작: \(session.parkingLot.name)")
                    })
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func getCurrentSession() -> AnyPublisher<ParkingSessionEntity?, Error> {
        return sessionRepository.getCurrentSession()
    }

    public func endSession() -> AnyPublisher<ParkingSessionEntity?, Error> {
        return sessionRepository.getCurrentSession()
            .flatMap { [weak self] currentSession -> AnyPublisher<ParkingSessionEntity?, Error> in
                guard let self = self else {
                    return Just(nil)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }

                guard let session = currentSession, session.isActive else {
                    return Fail(error: DomainError.noActiveSession)
                        .eraseToAnyPublisher()
                }

                let endedSession = session.ended()

                // 종료된 세션을 저장한 후 삭제
                return self.sessionRepository.saveSession(endedSession)
                    .flatMap { _ in
                        return self.sessionRepository.clearCurrentSession()
                            .map { _ in endedSession as ParkingSessionEntity? }
                    }
                    .handleEvents(receiveOutput: { _ in
                        self.sessionStateSubject.send(.ended(endedSession))
                        print("🏁 [ManageParkingSessionUseCase] 주차 세션 종료: \(session.parkingLot.name)")
                    })
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func updateAdditionalFreeMinutes(_ minutes: Int) -> AnyPublisher<ParkingSessionEntity?, Error> {
        return sessionRepository.getCurrentSession()
            .flatMap { [weak self] currentSession -> AnyPublisher<ParkingSessionEntity?, Error> in
                guard let self = self else {
                    return Just(nil)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }

                guard let session = currentSession, session.isActive else {
                    return Fail(error: DomainError.noActiveSession)
                        .eraseToAnyPublisher()
                }

                let updatedSession = session.withUpdatedFreeMinutes(minutes)

                return self.sessionRepository.saveSession(updatedSession)
                    .map { $0 as ParkingSessionEntity? }
                    .handleEvents(receiveOutput: { _ in
                        self.sessionStateSubject.send(.active(updatedSession))
                        print("🔄 [ManageParkingSessionUseCase] 무료시간 업데이트: \(minutes)분")
                    })
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func isSessionActive() -> AnyPublisher<Bool, Error> {
        return sessionRepository.isSessionActive()
    }

    public var currentSessionPublisher: AnyPublisher<ParkingSessionEntity?, Error> {
        return sessionRepository.sessionPublisher
    }

    public var sessionStatePublisher: AnyPublisher<SessionState, Error> {
        return sessionStateSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func observeSessionChanges() {
        sessionRepository.sessionPublisher
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ [ManageParkingSessionUseCase] 세션 관찰 에러: \(error)")
                    }
                },
                receiveValue: { [weak self] session in
                    guard let self = self else { return }

                    if let session = session, session.isActive {
                        self.sessionStateSubject.send(.active(session))
                    } else if let session = session, !session.isActive {
                        self.sessionStateSubject.send(.ended(session))
                    } else {
                        self.sessionStateSubject.send(.idle)
                    }
                }
            )
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}