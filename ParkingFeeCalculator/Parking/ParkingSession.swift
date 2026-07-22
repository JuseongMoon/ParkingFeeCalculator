//
//  ParkingSession.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import Foundation
// import ParkingFeeCore // 임시 제거

struct ParkingSession: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var startedAt: Date
    var endedAt: Date?
    var parkingLotProfile: ParkingLotProfile
    var driverProfile: DriverProfile
    var vehicleProfile: VehicleProfile
    var totalFee: Int
    var isActive: Bool
    var notes: String?
    var additionalFreeMinutes: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String = "",
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        parkingLotProfile: ParkingLotProfile,
        driverProfile: DriverProfile,
        vehicleProfile: VehicleProfile,
        totalFee: Int = 0,
        isActive: Bool = true,
        notes: String? = nil,
        additionalFreeMinutes: Int = 0
    ) {
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.parkingLotProfile = parkingLotProfile
        self.driverProfile = driverProfile
        self.vehicleProfile = vehicleProfile
        self.totalFee = totalFee
        self.isActive = isActive
        self.notes = notes
        self.additionalFreeMinutes = additionalFreeMinutes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Equatable
    static func == (lhs: ParkingSession, rhs: ParkingSession) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ParkingSession Extensions
extension ParkingSession {
    var duration: TimeInterval {
        let endTime = endedAt ?? Date()
        return endTime.timeIntervalSince(startedAt)
    }
    
    var durationHours: Double {
        return duration / 3600.0
    }
    
    var durationMinutes: Int {
        return Int(duration / 60.0)
    }
    
    var formattedDuration: String {
        let hours = Int(durationHours)
        let minutes = durationMinutes % 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
    
    var displayName: String {
        return name.isEmpty ? "주차 세션" : name
    }
    
    var isCompleted: Bool {
        return endedAt != nil && !isActive
    }
    
    var tariff: ParkingFeeCalculator {
        return parkingLotProfile.parkingFeeCalculator
    }
    
    mutating func endSession() {
        self.endedAt = Date()
        self.isActive = false
        self.updatedAt = Date()
    }
    
    mutating func updateFee(_ newFee: Int) {
        self.totalFee = newFee
        self.updatedAt = Date()
    }
}
