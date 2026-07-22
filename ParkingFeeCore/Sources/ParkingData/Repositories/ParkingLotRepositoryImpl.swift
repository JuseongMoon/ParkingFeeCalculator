//
//  ParkingLotRepositoryImpl.swift
//  ParkingData
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine
import ParkingDomain
import ParkingShared

/// ParkingLotRepository 구현체
public final class ParkingLotRepositoryImpl: ParkingLotRepository {
    private let dataSource: UserDefaultsDataSource
    private let dataKey = AppGroupConstants.Keys.parkingLots

    private let parkingLotsSubject = CurrentValueSubject<[ParkingLotEntity], Error>([])

    public init(dataSource: UserDefaultsDataSource) {
        self.dataSource = dataSource
        loadInitialData()
    }

    // MARK: - ParkingLotRepository Implementation

    public func getAllParkingLots() -> AnyPublisher<[ParkingLotEntity], Error> {
        let result = dataSource.load([EntityMapper.LegacyParkingLotProfile].self, forKey: dataKey)

        switch result {
        case .success(let legacyProfiles):
            let entities = (legacyProfiles ?? []).map { EntityMapper.toDomain($0) }
            parkingLotsSubject.send(entities)
            return Just(entities)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()

        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    public func getParkingLot(id: UUID) -> AnyPublisher<ParkingLotEntity?, Error> {
        return getAllParkingLots()
            .map { entities in
                entities.first { $0.id == id }
            }
            .eraseToAnyPublisher()
    }

    public func saveParkingLot(_ parkingLot: ParkingLotEntity) -> AnyPublisher<ParkingLotEntity, Error> {
        return getAllParkingLots()
            .flatMap { [weak self] currentEntities -> AnyPublisher<ParkingLotEntity, Error> in
                guard let self = self else {
                    return Fail(error: DataSourceError.accessDenied)
                        .eraseToAnyPublisher()
                }

                var updatedEntities = currentEntities
                if let index = updatedEntities.firstIndex(where: { $0.id == parkingLot.id }) {
                    // 업데이트
                    updatedEntities[index] = parkingLot
                    print("🔄 [ParkingLotRepository] 주차장 업데이트: \(parkingLot.name)")
                } else {
                    // 새로 추가
                    updatedEntities.append(parkingLot)
                    print("➕ [ParkingLotRepository] 새 주차장 추가: \(parkingLot.name)")
                }

                // Legacy 형태로 변환하여 저장
                let legacyProfiles = updatedEntities.map { EntityMapper.toLegacy($0) }
                let saveResult = self.dataSource.save(legacyProfiles, forKey: self.dataKey)

                switch saveResult {
                case .success:
                    self.parkingLotsSubject.send(updatedEntities)
                    return Just(parkingLot)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()

                case .failure(let error):
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    public func deleteParkingLot(id: UUID) -> AnyPublisher<Void, Error> {
        return getAllParkingLots()
            .flatMap { [weak self] currentEntities -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: DataSourceError.accessDenied)
                        .eraseToAnyPublisher()
                }

                let updatedEntities = currentEntities.filter { $0.id != id }
                let legacyProfiles = updatedEntities.map { EntityMapper.toLegacy($0) }
                let saveResult = self.dataSource.save(legacyProfiles, forKey: self.dataKey)

                switch saveResult {
                case .success:
                    self.parkingLotsSubject.send(updatedEntities)
                    print("🗑 [ParkingLotRepository] 주차장 삭제 완료: \(id)")
                    return Just(())
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()

                case .failure(let error):
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    public var parkingLotsPublisher: AnyPublisher<[ParkingLotEntity], Error> {
        return parkingLotsSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func loadInitialData() {
        _ = getAllParkingLots()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ [ParkingLotRepository] 초기 데이터 로드 실패: \(error)")
                    }
                },
                receiveValue: { _ in
                    print("✅ [ParkingLotRepository] 초기 데이터 로드 완료")
                }
            )
    }
}