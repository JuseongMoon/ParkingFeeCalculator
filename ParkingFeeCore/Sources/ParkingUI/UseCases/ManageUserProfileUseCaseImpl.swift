//
//  ManageUserProfileUseCaseImpl.swift
//  ParkingUI
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine
import ParkingDomain

/// 사용자 프로필 관리 Use Case 구현체
public final class ManageUserProfileUseCaseImpl: ManageUserProfileUseCase {
    private let userProfileRepository: UserProfileRepository

    public init(userProfileRepository: UserProfileRepository) {
        self.userProfileRepository = userProfileRepository
    }

    // MARK: - ManageUserProfileUseCase Implementation

    public func getCurrentVehicleProfile() -> AnyPublisher<VehicleProfile, Error> {
        return userProfileRepository.getVehicleProfile()
    }

    public func updateVehicleProfile(_ profile: VehicleProfile) -> AnyPublisher<VehicleProfile, Error> {
        return userProfileRepository.saveVehicleProfile(profile)
            .handleEvents(receiveOutput: { _ in
                print("🚗 [ManageUserProfileUseCase] 차량 프로필 업데이트: \(profile.displayName)")
            })
            .eraseToAnyPublisher()
    }

    public func getCurrentDriverProfile() -> AnyPublisher<DriverProfile, Error> {
        return userProfileRepository.getDriverProfile()
    }

    public func updateDriverProfile(_ profile: DriverProfile) -> AnyPublisher<DriverProfile, Error> {
        return userProfileRepository.saveDriverProfile(profile)
            .handleEvents(receiveOutput: { _ in
                print("👤 [ManageUserProfileUseCase] 운전자 프로필 업데이트: \(profile.displayName)")
            })
            .eraseToAnyPublisher()
    }

    public var vehicleProfilePublisher: AnyPublisher<VehicleProfile, Error> {
        return userProfileRepository.vehicleProfilePublisher
    }

    public var driverProfilePublisher: AnyPublisher<DriverProfile, Error> {
        return userProfileRepository.driverProfilePublisher
    }
}