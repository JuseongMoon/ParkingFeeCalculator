//
//  VehicleProfile.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/16/25.
//

import Foundation

public struct VehicleProfile: Codable, Identifiable, Equatable, Hashable {
    public var id: UUID = UUID()
    public var vehicleSize: VehicleSize
    public var isElectric: Bool
    public var isHydrogen: Bool
    public var isHybrid: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
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

public enum VehicleSize: String, CaseIterable, Codable {
    case light = "light"
    case normal = "normal"
    case large = "large"
    
    public var displayName: String {
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
public extension VehicleProfile {
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