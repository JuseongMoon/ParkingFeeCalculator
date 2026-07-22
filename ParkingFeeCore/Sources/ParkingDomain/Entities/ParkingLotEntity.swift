//
//  ParkingLotEntity.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation

/// 주차장 도메인 엔티티
public struct ParkingLotEntity: Identifiable, Equatable, Hashable {
    public let id: UUID
    public let name: String
    public let address: String
    public let feeCalculationRules: FeeCalculationRules
    public let discountRules: DiscountRules
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        address: String,
        feeCalculationRules: FeeCalculationRules,
        discountRules: DiscountRules = DiscountRules(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.feeCalculationRules = feeCalculationRules
        self.discountRules = discountRules
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - ParkingLotEntity Extensions
public extension ParkingLotEntity {
    var displayName: String {
        return name.isEmpty ? "미등록 주차장" : name
    }

    var isComplete: Bool {
        return !name.isEmpty && !address.isEmpty
    }

    func updated(name: String? = nil, address: String? = nil) -> ParkingLotEntity {
        return ParkingLotEntity(
            id: self.id,
            name: name ?? self.name,
            address: address ?? self.address,
            feeCalculationRules: self.feeCalculationRules,
            discountRules: self.discountRules,
            createdAt: self.createdAt,
            updatedAt: Date()
        )
    }
}