//
//  ParkingLotProfile.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/13/25.
//

import Foundation

struct ParkingLotProfile: Codable, Identifiable {
    var id: UUID
    var name: String
    var address: String
    var parkingFeeCalculator: ParkingFeeCalculator
    var specialConditionDiscounts: SpecialConditionDiscounts
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String = "",
        address: String = "",
        parkingFeeCalculator: ParkingFeeCalculator = ParkingFeeCalculator(),
        specialConditionDiscounts: SpecialConditionDiscounts = SpecialConditionDiscounts(),
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
    init(
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
extension ParkingLotProfile {
    var displayName: String {
        return name.isEmpty ? "미등록 주차장" : name
    }

    var isProfileComplete: Bool {
        return !name.isEmpty && !address.isEmpty
    }
}

// MARK: - Special Condition Discounts
struct SpecialConditionDiscounts: Codable {
    var mildDiscountPercentage: Double?
    var severeDiscountPercentage: Double?
    var nationalMeritDiscountPercentage: Double?
    var exemplaryTaxpayerDiscountPercentage: Double?
    var multiChildDiscountPercentage: Double?
    var seniorDiscountPercentage: Double?
    
    // 차량 관련 할인
    var lightCarDiscountPercentage: Double?
    var normalCarDiscountPercentage: Double?
    var largeCarDiscountPercentage: Double?

    var electricDiscountPercentage: Double?
    var hydrogenDiscountPercentage: Double?
    var hybridDiscountPercentage: Double?
    
    init(
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
    
    func getDiscountPercentage(for condition: SpecialCondition) -> Double? {
        switch condition {
        case .mildDisabled:
            return mildDiscountPercentage
        case .severeDisabled:
            return severeDiscountPercentage
        case .nationalMerit:
            return nationalMeritDiscountPercentage
        case .exemplaryTaxpayer:
            return exemplaryTaxpayerDiscountPercentage
        case .multiChild:
            return multiChildDiscountPercentage
        case .senior:
            return seniorDiscountPercentage
        case .lightCar:
            return lightCarDiscountPercentage
        case .normalCar:
            return normalCarDiscountPercentage
        case .largeCar:
            return largeCarDiscountPercentage

        case .electric:
            return electricDiscountPercentage
        case .hydrogen:
            return hydrogenDiscountPercentage
        case .hybrid:
            return hybridDiscountPercentage
        }
    }
    
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
    
    var displayDescription: String {
        var descriptions: [String] = []
        
        if let mild = mildDiscountPercentage {
            descriptions.append("경증 \(Int(mild))%")
        }
        
        if let severe = severeDiscountPercentage {
            descriptions.append("중증 \(Int(severe))%")
        }
        
        if let nationalMerit = nationalMeritDiscountPercentage {
            descriptions.append("국가유공자 \(Int(nationalMerit))%")
        }
        
        if let exemplaryTaxpayer = exemplaryTaxpayerDiscountPercentage {
            descriptions.append("모범납세자 \(Int(exemplaryTaxpayer))%")
        }
        
        if let multiChild = multiChildDiscountPercentage {
            descriptions.append("다자녀 \(Int(multiChild))%")
        }
        
        if let senior = seniorDiscountPercentage {
            descriptions.append("고령자 \(Int(senior))%")
        }
        
        if let lightCar = lightCarDiscountPercentage {
            descriptions.append("경차 \(Int(lightCar))%")
        }
        
        if let normalCar = normalCarDiscountPercentage {
            descriptions.append("일반차 \(Int(normalCar))%")
        }
        
        if let largeCar = largeCarDiscountPercentage {
            descriptions.append("대형차 \(Int(largeCar))%")
        }
        

        
        if let electric = electricDiscountPercentage {
            descriptions.append("전기차 \(Int(electric))%")
        }
        
        if let hydrogen = hydrogenDiscountPercentage {
            descriptions.append("수소차 \(Int(hydrogen))%")
        }
        
        if let hybrid = hybridDiscountPercentage {
            descriptions.append("하이브리드 \(Int(hybrid))%")
        }
        
        if descriptions.isEmpty {
            return "할인 없음"
        }
        
        return descriptions.joined(separator: ", ")
    }
}

enum SpecialCondition: Codable {
    case mildDisabled
    case severeDisabled
    case nationalMerit
    case exemplaryTaxpayer
    case multiChild
    case senior
    case lightCar
    case normalCar
    case largeCar

    case electric
    case hydrogen
    case hybrid
    
    var displayName: String {
        switch self {
        case .mildDisabled:
            return "경증 장애인"
        case .severeDisabled:
            return "중증 장애인"
        case .nationalMerit:
            return "국가유공자"
        case .exemplaryTaxpayer:
            return "모범납세자"
        case .multiChild:
            return "다자녀"
        case .senior:
            return "고령자"
        case .lightCar:
            return "경차"
        case .normalCar:
            return "일반차"
        case .largeCar:
            return "대형차"

        case .electric:
            return "전기차"
        case .hydrogen:
            return "수소차"
        case .hybrid:
            return "하이브리드"
        }
    }
}


