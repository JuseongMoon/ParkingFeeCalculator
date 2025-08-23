//
//  VehicleProfile.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import Foundation

struct VehicleProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var vehicleSize: VehicleSize
    var isElectric: Bool
    var isHydrogen: Bool
    var isHybrid: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        vehicleSize: VehicleSize = .normal,
        isElectric: Bool = false,
        isHydrogen: Bool = false,
        isHybrid: Bool = false
    ) {
        self.vehicleSize = vehicleSize
        self.isElectric = isElectric
        self.isHydrogen = isHydrogen
        self.isHybrid = isHybrid
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum VehicleSize: String, CaseIterable, Codable {
    case light = "light"
    case normal = "normal"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .light:
            return "경차"
        case .normal:
            return "일반"
        case .large:
            return "대형"
        }
    }
}

// MARK: - VehicleProfile Extensions
extension VehicleProfile {
    var displayName: String {
        return vehicleSize.displayName
    }
    
    var isEcoFriendly: Bool {
        return isElectric || isHydrogen || isHybrid
    }
    
    var ecoFriendlyType: String {
        var types: [String] = []
        if isElectric { types.append("전기차") }
        if isHydrogen { types.append("수소차") }
        if isHybrid { types.append("하이브리드") }
        return types.isEmpty ? "일반" : types.joined(separator: ", ")
    }
    
    var isProfileComplete: Bool {
        return true // 차량 크기만 있으면 완성된 것으로 간주
    }
}
