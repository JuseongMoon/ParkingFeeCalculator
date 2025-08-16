//
//  VehicleProfile.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import Foundation

struct VehicleProfile: Codable, Identifiable {
    let id = UUID()
    var vehicleSize: VehicleSize
    var isLowEmission: Bool
    var isElectricHydrogen: Bool
    var isHybrid: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        vehicleSize: VehicleSize = .normal,
        isLowEmission: Bool = false,
        isElectricHydrogen: Bool = false,
        isHybrid: Bool = false
    ) {
        self.vehicleSize = vehicleSize
        self.isLowEmission = isLowEmission
        self.isElectricHydrogen = isElectricHydrogen
        self.isHybrid = isHybrid
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum VehicleSize: String, CaseIterable, Codable {
    case light = "light"
    case normal = "normal"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .light:
            return "경차"
        case .normal:
            return "일반차"
        case .medium:
            return "중형차"
        case .large:
            return "대형차"
        }
    }
    
    var defaultRateMultiplier: Double {
        switch self {
        case .light:
            return 0.8
        case .normal:
            return 1.0
        case .medium:
            return 1.2
        case .large:
            return 1.5
        }
    }
}

// MARK: - VehicleProfile Extensions
extension VehicleProfile {
    var displayName: String {
        return vehicleSize.displayName
    }
    
    var isEcoFriendly: Bool {
        return isLowEmission || isElectricHydrogen || isHybrid
    }
    
    var ecoFriendlyType: String {
        var types: [String] = []
        if isLowEmission { types.append("저공해 인증") }
        if isElectricHydrogen { types.append("전기/수소") }
        if isHybrid { types.append("하이브리드") }
        return types.isEmpty ? "일반" : types.joined(separator: ", ")
    }
    
    var isProfileComplete: Bool {
        return true // 차량 크기만 있으면 완성된 것으로 간주
    }
}
