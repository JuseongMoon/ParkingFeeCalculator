//
//  VehicleProfile.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation

/// 차량 프로필 Value Object
public struct VehicleProfile: Equatable, Hashable, Codable {
    public let size: VehicleSize
    public let fuelType: VehicleFuelType

    public init(
        size: VehicleSize = .normal,
        fuelType: VehicleFuelType = .gasoline
    ) {
        self.size = size
        self.fuelType = fuelType
    }
}

// MARK: - VehicleProfile Extensions
public extension VehicleProfile {
    var displayName: String {
        return "\(size.displayName) \(fuelType.displayName)"
    }

    var isEcoFriendly: Bool {
        return fuelType.isEcoFriendly
    }

    var ecoFriendlyType: String {
        return fuelType.isEcoFriendly ? fuelType.displayName : "일반"
    }

    // Legacy compatibility
    var isElectric: Bool { fuelType == .electric }
    var isHydrogen: Bool { fuelType == .hydrogen }
    var isHybrid: Bool { fuelType == .hybrid }
}

/// 차량 크기
public enum VehicleSize: String, CaseIterable, Codable {
    case light = "light"
    case normal = "normal"
    case large = "large"

    public var displayName: String {
        switch self {
        case .light: return "경차"
        case .normal: return "일반"
        case .large: return "대형"
        }
    }
}

/// 차량 연료 타입
public enum VehicleFuelType: String, CaseIterable, Codable {
    case gasoline = "gasoline"
    case diesel = "diesel"
    case electric = "electric"
    case hydrogen = "hydrogen"
    case hybrid = "hybrid"

    public var displayName: String {
        switch self {
        case .gasoline: return "휘발유"
        case .diesel: return "경유"
        case .electric: return "전기차"
        case .hydrogen: return "수소차"
        case .hybrid: return "하이브리드"
        }
    }

    public var isEcoFriendly: Bool {
        switch self {
        case .electric, .hydrogen, .hybrid: return true
        case .gasoline, .diesel: return false
        }
    }
}