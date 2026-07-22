//
//  ParkingSessionRepositoryImpl.swift
//  ParkingData
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine
import ParkingDomain
import ParkingShared

/// ParkingSessionRepository 구현체
public final class ParkingSessionRepositoryImpl: ParkingSessionRepository {
    private let dataSource: UserDefaultsDataSource
    private let sessionKey = AppGroupConstants.Keys.currentSession

    private let sessionSubject = CurrentValueSubject<ParkingSessionEntity?, Error>(nil)

    public init(dataSource: UserDefaultsDataSource) {
        self.dataSource = dataSource
        loadInitialSession()
    }

    // MARK: - ParkingSessionRepository Implementation

    public func getCurrentSession() -> AnyPublisher<ParkingSessionEntity?, Error> {
        let result = dataSource.load(LegacyParkingSession.self, forKey: sessionKey)

        switch result {
        case .success(let legacySession):
            let session = legacySession.map { toDomainSession($0) }
            sessionSubject.send(session)
            return Just(session)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()

        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    public func saveSession(_ session: ParkingSessionEntity) -> AnyPublisher<ParkingSessionEntity, Error> {
        let legacySession = toLegacySession(session)
        let saveResult = dataSource.save(legacySession, forKey: sessionKey)

        switch saveResult {
        case .success:
            sessionSubject.send(session)
            print("✅ [ParkingSessionRepository] 세션 저장 완료: \(session.parkingLot.name)")
            return Just(session)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()

        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    public func clearCurrentSession() -> AnyPublisher<Void, Error> {
        let removeResult = dataSource.remove(forKey: sessionKey)

        switch removeResult {
        case .success:
            sessionSubject.send(nil)
            print("🗑 [ParkingSessionRepository] 세션 삭제 완료")
            return Just(())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()

        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    public var sessionPublisher: AnyPublisher<ParkingSessionEntity?, Error> {
        return sessionSubject.eraseToAnyPublisher()
    }

    public func isSessionActive() -> AnyPublisher<Bool, Error> {
        return getCurrentSession()
            .map { session in
                session?.isActive ?? false
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func loadInitialSession() {
        _ = getCurrentSession()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ [ParkingSessionRepository] 초기 세션 로드 실패: \(error)")
                    }
                },
                receiveValue: { session in
                    if let session = session {
                        print("✅ [ParkingSessionRepository] 기존 세션 로드 완료: \(session.parkingLot.name)")
                    } else {
                        print("ℹ️ [ParkingSessionRepository] 활성 세션 없음")
                    }
                }
            )
    }

    // MARK: - Legacy Session Mapping

    /// Legacy 세션 구조 (기존 SharedParkingSession과 호환)
    private struct LegacyParkingSession: Codable {
        let id: UUID
        let startTime: Date
        let endTime: Date?
        let parkingLot: EntityMapper.LegacyParkingLotProfile
        let vehicle: EntityMapper.LegacyVehicleProfile
        let driver: EntityMapper.LegacyDriverProfile
        let additionalFreeMinutes: Int
        let status: String
        let createdAt: Date
        let updatedAt: Date
    }

    /// Legacy 세션을 Domain 세션으로 변환
    private func toDomainSession(_ legacy: LegacyParkingSession) -> ParkingSessionEntity {
        let domainParkingLot = EntityMapper.toDomain(legacy.parkingLot)
        let domainVehicle = EntityMapper.toDomain(legacy.vehicle)
        let domainDriver = EntityMapper.toDomain(legacy.driver)

        let status: ParkingSessionStatus
        switch legacy.status {
        case "completed":
            status = .completed
        case "cancelled":
            status = .cancelled
        default:
            status = .active
        }

        return ParkingSessionEntity(
            id: legacy.id,
            startTime: legacy.startTime,
            endTime: legacy.endTime,
            parkingLot: domainParkingLot,
            vehicle: domainVehicle,
            driver: domainDriver,
            additionalFreeMinutes: legacy.additionalFreeMinutes,
            status: status,
            createdAt: legacy.createdAt,
            updatedAt: legacy.updatedAt
        )
    }

    /// Domain 세션을 Legacy 세션으로 변환
    private func toLegacySession(_ domain: ParkingSessionEntity) -> LegacyParkingSession {
        let legacyParkingLot = EntityMapper.toLegacy(domain.parkingLot)
        let legacyVehicle = EntityMapper.toLegacy(domain.vehicle)
        let legacyDriver = EntityMapper.toLegacy(domain.driver)

        return LegacyParkingSession(
            id: domain.id,
            startTime: domain.startTime,
            endTime: domain.endTime,
            parkingLot: legacyParkingLot,
            vehicle: legacyVehicle,
            driver: legacyDriver,
            additionalFreeMinutes: domain.additionalFreeMinutes,
            status: domain.status.rawValue,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }
}