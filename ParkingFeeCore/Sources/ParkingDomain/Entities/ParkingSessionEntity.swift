//
//  ParkingSessionEntity.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation

/// 주차 세션 도메인 엔티티
public struct ParkingSessionEntity: Identifiable, Equatable {
    public let id: UUID
    public let startTime: Date
    public let endTime: Date?
    public let parkingLot: ParkingLotEntity
    public let vehicle: VehicleProfile
    public let driver: DriverProfile
    public let additionalFreeMinutes: Int
    public let status: ParkingSessionStatus
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        parkingLot: ParkingLotEntity,
        vehicle: VehicleProfile,
        driver: DriverProfile,
        additionalFreeMinutes: Int = 0,
        status: ParkingSessionStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.parkingLot = parkingLot
        self.vehicle = vehicle
        self.driver = driver
        self.additionalFreeMinutes = additionalFreeMinutes
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - ParkingSessionEntity Extensions
public extension ParkingSessionEntity {
    /// 현재 경과 시간 (초)
    var elapsedTime: TimeInterval {
        let currentTime = endTime ?? Date()
        return currentTime.timeIntervalSince(startTime)
    }

    /// 실제 과금 시간 (무료 시간 제외, 초)
    var chargeableTime: TimeInterval {
        let totalFreeSeconds = TimeInterval(additionalFreeMinutes * 60)
        let elapsed = elapsedTime
        return max(0, elapsed - totalFreeSeconds)
    }

    /// 세션이 활성 상태인지 확인
    var isActive: Bool {
        return status == .active && endTime == nil
    }

    /// 할인 정보 텍스트
    var discountInfo: String? {
        var discounts: [String] = []

        if driver.hasAnySpecialCondition {
            discounts.append(driver.displayName)
        }

        if vehicle.isEcoFriendly {
            discounts.append(vehicle.ecoFriendlyType)
        }

        return discounts.isEmpty ? nil : discounts.joined(separator: ", ")
    }

    /// 세션 종료
    func ended(at date: Date = Date()) -> ParkingSessionEntity {
        return ParkingSessionEntity(
            id: self.id,
            startTime: self.startTime,
            endTime: date,
            parkingLot: self.parkingLot,
            vehicle: self.vehicle,
            driver: self.driver,
            additionalFreeMinutes: self.additionalFreeMinutes,
            status: .completed,
            createdAt: self.createdAt,
            updatedAt: date
        )
    }

    /// 추가 무료시간 업데이트
    func withUpdatedFreeMinutes(_ minutes: Int) -> ParkingSessionEntity {
        return ParkingSessionEntity(
            id: self.id,
            startTime: self.startTime,
            endTime: self.endTime,
            parkingLot: self.parkingLot,
            vehicle: self.vehicle,
            driver: self.driver,
            additionalFreeMinutes: minutes,
            status: self.status,
            createdAt: self.createdAt,
            updatedAt: Date()
        )
    }
}

/// 주차 세션 상태
public enum ParkingSessionStatus: String, CaseIterable, Codable {
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"

    public var displayName: String {
        switch self {
        case .active:
            return "진행중"
        case .completed:
            return "완료"
        case .cancelled:
            return "취소"
        }
    }
}