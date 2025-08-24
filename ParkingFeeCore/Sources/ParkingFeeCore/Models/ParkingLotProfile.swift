//
//  ParkingLotProfile.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/13/25.
//

import Foundation

public struct ParkingLotProfile: Codable, Identifiable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var address: String
    public var parkingFeeCalculator: ParkingFeeCalculator
    public var specialConditionDiscounts: SpecialConditionDiscounts
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        name: String = "",
        address: String = "",
        parkingFeeCalculator: ParkingFeeCalculator = ParkingFeeCalculator(),
        specialConditionDiscounts: SpecialConditionDiscounts = SpecialConditionDiscounts()
    ) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.parkingFeeCalculator = parkingFeeCalculator
        self.specialConditionDiscounts = specialConditionDiscounts
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 기존 ID와 생성일을 유지하면서 업데이트하기 위한 초기화 메서드
    public init(
        id: UUID,
        name: String,
        address: String,
        parkingFeeCalculator: ParkingFeeCalculator,
        specialConditionDiscounts: SpecialConditionDiscounts,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.parkingFeeCalculator = parkingFeeCalculator
        self.specialConditionDiscounts = specialConditionDiscounts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - ParkingLotProfile Extensions
public extension ParkingLotProfile {
    var displayName: String {
        return name.isEmpty ? "미등록 주차장" : name
    }

    var isProfileComplete: Bool {
        return !name.isEmpty && !address.isEmpty
    }
}

// MARK: - Special Condition Discounts
public struct SpecialConditionDiscounts: Codable, Equatable, Hashable {
    public var mildDiscountPercentage: Double?
    public var severeDiscountPercentage: Double?
    public var nationalMeritDiscountPercentage: Double?
    public var exemplaryTaxpayerDiscountPercentage: Double?
    public var multiChildDiscountPercentage: Double?
    public var seniorDiscountPercentage: Double?
    
    // 차량 관련 할인
    public var lightCarDiscountPercentage: Double?
    public var normalCarDiscountPercentage: Double?
    public var largeCarDiscountPercentage: Double?

    public var electricDiscountPercentage: Double?
    public var hydrogenDiscountPercentage: Double?
    public var hybridDiscountPercentage: Double?
    
    public init(
        mildDiscountPercentage: Double? = nil,
        severeDiscountPercentage: Double? = nil,
        nationalMeritDiscountPercentage: Double? = nil,
        exemplaryTaxpayerDiscountPercentage: Double? = nil,
        multiChildDiscountPercentage: Double? = nil,
        seniorDiscountPercentage: Double? = nil,
        lightCarDiscountPercentage: Double? = nil,
        normalCarDiscountPercentage: Double? = nil,
        largeCarDiscountPercentage: Double? = nil,
        electricDiscountPercentage: Double? = nil,
        hydrogenDiscountPercentage: Double? = nil,
        hybridDiscountPercentage: Double? = nil
    ) {
        self.mildDiscountPercentage = mildDiscountPercentage
        self.severeDiscountPercentage = severeDiscountPercentage
        self.nationalMeritDiscountPercentage = nationalMeritDiscountPercentage
        self.exemplaryTaxpayerDiscountPercentage = exemplaryTaxpayerDiscountPercentage
        self.multiChildDiscountPercentage = multiChildDiscountPercentage
        self.seniorDiscountPercentage = seniorDiscountPercentage
        self.lightCarDiscountPercentage = lightCarDiscountPercentage
        self.normalCarDiscountPercentage = normalCarDiscountPercentage
        self.largeCarDiscountPercentage = largeCarDiscountPercentage
        self.electricDiscountPercentage = electricDiscountPercentage
        self.hydrogenDiscountPercentage = hydrogenDiscountPercentage
        self.hybridDiscountPercentage = hybridDiscountPercentage
    }
}

// MARK: - SpecialConditionDiscounts Extensions
public extension SpecialConditionDiscounts {
    /// 설정된 할인이 하나라도 있는지 확인합니다
    var hasAnyDiscount: Bool {
        return mildDiscountPercentage != nil ||
               severeDiscountPercentage != nil ||
               nationalMeritDiscountPercentage != nil ||
               exemplaryTaxpayerDiscountPercentage != nil ||
               multiChildDiscountPercentage != nil ||
               seniorDiscountPercentage != nil ||
               lightCarDiscountPercentage != nil ||
               normalCarDiscountPercentage != nil ||
               largeCarDiscountPercentage != nil ||
               electricDiscountPercentage != nil ||
               hydrogenDiscountPercentage != nil ||
               hybridDiscountPercentage != nil
    }
    
    /// 운전자 관련 할인이 있는지 확인합니다
    var hasDriverDiscounts: Bool {
        return mildDiscountPercentage != nil ||
               severeDiscountPercentage != nil ||
               nationalMeritDiscountPercentage != nil ||
               exemplaryTaxpayerDiscountPercentage != nil ||
               multiChildDiscountPercentage != nil ||
               seniorDiscountPercentage != nil
    }
    
    /// 차량 관련 할인이 있는지 확인합니다
    var hasVehicleDiscounts: Bool {
        return lightCarDiscountPercentage != nil ||
               normalCarDiscountPercentage != nil ||
               largeCarDiscountPercentage != nil ||
               electricDiscountPercentage != nil ||
               hydrogenDiscountPercentage != nil ||
               hybridDiscountPercentage != nil
    }
    
    /// 설정된 할인들의 표시 설명을 반환합니다
    var displayDescription: String {
        var descriptions: [String] = []
        
        // 운전자 관련 할인
        if let percentage = mildDiscountPercentage {
            descriptions.append("경증 장애인 \(Int(percentage))%")
        }
        if let percentage = severeDiscountPercentage {
            descriptions.append("중증 장애인 \(Int(percentage))%")
        }
        if let percentage = nationalMeritDiscountPercentage {
            descriptions.append("국가유공자 \(Int(percentage))%")
        }
        if let percentage = exemplaryTaxpayerDiscountPercentage {
            descriptions.append("모범납세자 \(Int(percentage))%")
        }
        if let percentage = multiChildDiscountPercentage {
            descriptions.append("다자녀 \(Int(percentage))%")
        }
        if let percentage = seniorDiscountPercentage {
            descriptions.append("고령자 \(Int(percentage))%")
        }
        
        // 차량 크기별 할인
        if let percentage = lightCarDiscountPercentage {
            descriptions.append("경차 \(Int(percentage))%")
        }
        if let percentage = normalCarDiscountPercentage {
            descriptions.append("일반차 \(Int(percentage))%")
        }
        if let percentage = largeCarDiscountPercentage {
            descriptions.append("대형차 \(Int(percentage))%")
        }
        
        // 친환경 차량 할인
        if let percentage = electricDiscountPercentage {
            descriptions.append("전기차 \(Int(percentage))%")
        }
        if let percentage = hydrogenDiscountPercentage {
            descriptions.append("수소차 \(Int(percentage))%")
        }
        if let percentage = hybridDiscountPercentage {
            descriptions.append("하이브리드 \(Int(percentage))%")
        }
        
        return descriptions.isEmpty ? "할인 없음" : descriptions.joined(separator: ", ")
    }
}