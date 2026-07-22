//
//  UserProfileRepositoryImpl.swift
//  ParkingData
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine
import ParkingDomain
import ParkingShared

/// UserProfileRepository 구현체
public final class UserProfileRepositoryImpl: UserProfileRepository {
    private let dataSource: UserDefaultsDataSource
    private let vehicleKey = AppGroupConstants.Keys.vehicleProfile
    private let driverKey = AppGroupConstants.Keys.driverProfile

    private let vehicleSubject = CurrentValueSubject<VehicleProfile, Error>(VehicleProfile())
    private let driverSubject = CurrentValueSubject<DriverProfile, Error>(DriverProfile())

    public init(dataSource: UserDefaultsDataSource) {
        self.dataSource = dataSource
        loadInitialProfiles()
    }

    // MARK: - UserProfileRepository Implementation

    public func getVehicleProfile() -> AnyPublisher<VehicleProfile, Error> {
        let result = dataSource.load(EntityMapper.LegacyVehicleProfile.self, forKey: vehicleKey)

        switch result {
        case .success(let legacyProfile):
            let profile = legacyProfile.map { EntityMapper.toDomain($0) } ?? VehicleProfile()
            vehicleSubject.send(profile)
            return Just(profile)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()

        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    public func saveVehicleProfile(_ profile: VehicleProfile) -> AnyPublisher<VehicleProfile, Error> {
        let legacyProfile = EntityMapper.toLegacy(profile)
        let saveResult = dataSource.save(legacyProfile, forKey: vehicleKey)

        switch saveResult {
        case .success:
            vehicleSubject.send(profile)
            print("✅ [UserProfileRepository] 차량 프로필 저장 완료")
            return Just(profile)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()

        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    public func getDriverProfile() -> AnyPublisher<DriverProfile, Error> {
        let result = dataSource.load(EntityMapper.LegacyDriverProfile.self, forKey: driverKey)

        switch result {
        case .success(let legacyProfile):
            let profile = legacyProfile.map { EntityMapper.toDomain($0) } ?? DriverProfile()
            driverSubject.send(profile)
            return Just(profile)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()

        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    public func saveDriverProfile(_ profile: DriverProfile) -> AnyPublisher<DriverProfile, Error> {
        let legacyProfile = EntityMapper.toLegacy(profile)
        let saveResult = dataSource.save(legacyProfile, forKey: driverKey)

        switch saveResult {
        case .success:
            driverSubject.send(profile)
            print("✅ [UserProfileRepository] 운전자 프로필 저장 완료")
            return Just(profile)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()

        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    public var vehicleProfilePublisher: AnyPublisher<VehicleProfile, Error> {
        return vehicleSubject.eraseToAnyPublisher()
    }

    public var driverProfilePublisher: AnyPublisher<DriverProfile, Error> {
        return driverSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func loadInitialProfiles() {
        // 차량 프로필 초기 로드
        _ = getVehicleProfile()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ [UserProfileRepository] 차량 프로필 초기 로드 실패: \(error)")
                    }
                },
                receiveValue: { _ in
                    print("✅ [UserProfileRepository] 차량 프로필 초기 로드 완료")
                }
            )

        // 운전자 프로필 초기 로드
        _ = getDriverProfile()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ [UserProfileRepository] 운전자 프로필 초기 로드 실패: \(error)")
                    }
                },
                receiveValue: { _ in
                    print("✅ [UserProfileRepository] 운전자 프로필 초기 로드 완료")
                }
            )
    }
}