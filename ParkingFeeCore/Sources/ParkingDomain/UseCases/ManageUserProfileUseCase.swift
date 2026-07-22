//
//  ManageUserProfileUseCase.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine

/// 사용자 프로필 관리 Use Case 인터페이스
public protocol ManageUserProfileUseCase {
    /// 현재 차량 프로필을 가져옵니다
    func getCurrentVehicleProfile() -> AnyPublisher<VehicleProfile, Error>

    /// 차량 프로필을 업데이트합니다
    func updateVehicleProfile(_ profile: VehicleProfile) -> AnyPublisher<VehicleProfile, Error>

    /// 현재 운전자 프로필을 가져옵니다
    func getCurrentDriverProfile() -> AnyPublisher<DriverProfile, Error>

    /// 운전자 프로필을 업데이트합니다
    func updateDriverProfile(_ profile: DriverProfile) -> AnyPublisher<DriverProfile, Error>

    /// 차량 프로필 변경을 관찰합니다
    var vehicleProfilePublisher: AnyPublisher<VehicleProfile, Error> { get }

    /// 운전자 프로필 변경을 관찰합니다
    var driverProfilePublisher: AnyPublisher<DriverProfile, Error> { get }
}