//
//  UserProfileRepository.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine

/// 사용자 프로필 데이터 저장소 인터페이스
public protocol UserProfileRepository {
    /// 현재 차량 프로필을 가져옵니다
    func getVehicleProfile() -> AnyPublisher<VehicleProfile, Error>

    /// 차량 프로필을 저장합니다
    func saveVehicleProfile(_ profile: VehicleProfile) -> AnyPublisher<VehicleProfile, Error>

    /// 현재 운전자 프로필을 가져옵니다
    func getDriverProfile() -> AnyPublisher<DriverProfile, Error>

    /// 운전자 프로필을 저장합니다
    func saveDriverProfile(_ profile: DriverProfile) -> AnyPublisher<DriverProfile, Error>

    /// 차량 프로필 변경을 관찰합니다
    var vehicleProfilePublisher: AnyPublisher<VehicleProfile, Error> { get }

    /// 운전자 프로필 변경을 관찰합니다
    var driverProfilePublisher: AnyPublisher<DriverProfile, Error> { get }
}