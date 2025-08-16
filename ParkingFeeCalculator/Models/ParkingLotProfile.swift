//
//  ParkingLotProfile.swift
//  ParkingFeeCalculator
//
//  Created by GPT-5 on 8/13/25.
//

import Foundation

struct ParkingLotProfile: Codable, Identifiable {
    let id = UUID()
    var name: String
    var address: String
    var parkingFeeCalculator: ParkingFeeCalculator
    var specialConditionDiscounts: SpecialConditionDiscounts
    var isOpen: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String = "",
        address: String = "",
        parkingFeeCalculator: ParkingFeeCalculator = ParkingFeeCalculator(),
        specialConditionDiscounts: SpecialConditionDiscounts = SpecialConditionDiscounts(),
        isOpen: Bool = true
    ) {
        self.name = name
        self.address = address
        self.parkingFeeCalculator = parkingFeeCalculator
        self.specialConditionDiscounts = specialConditionDiscounts
        self.isOpen = isOpen
        self.createdAt = Date()
        self.updatedAt = Date()
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
    var mediumCarDiscountPercentage: Double?
    var largeCarDiscountPercentage: Double?
    var lowEmissionDiscountPercentage: Double?
    var electricHydrogenDiscountPercentage: Double?
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
        mediumCarDiscountPercentage: Double? = nil,
        largeCarDiscountPercentage: Double? = nil,
        lowEmissionDiscountPercentage: Double? = nil,
        electricHydrogenDiscountPercentage: Double? = nil,
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
        self.mediumCarDiscountPercentage = mediumCarDiscountPercentage
        self.largeCarDiscountPercentage = largeCarDiscountPercentage
        self.lowEmissionDiscountPercentage = lowEmissionDiscountPercentage
        self.electricHydrogenDiscountPercentage = electricHydrogenDiscountPercentage
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
        case .mediumCar:
            return mediumCarDiscountPercentage
        case .largeCar:
            return largeCarDiscountPercentage
        case .lowEmission:
            return lowEmissionDiscountPercentage
        case .electricHydrogen:
            return electricHydrogenDiscountPercentage
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
               mediumCarDiscountPercentage != nil ||
               largeCarDiscountPercentage != nil ||
               lowEmissionDiscountPercentage != nil ||
               electricHydrogenDiscountPercentage != nil ||
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
        
        if let mediumCar = mediumCarDiscountPercentage {
            descriptions.append("중형차 \(Int(mediumCar))%")
        }
        
        if let largeCar = largeCarDiscountPercentage {
            descriptions.append("대형차 \(Int(largeCar))%")
        }
        
        if let lowEmission = lowEmissionDiscountPercentage {
            descriptions.append("저공해인증 \(Int(lowEmission))%")
        }
        
        if let electricHydrogen = electricHydrogenDiscountPercentage {
            descriptions.append("전기/수소 \(Int(electricHydrogen))%")
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
    case mediumCar
    case largeCar
    case lowEmission
    case electricHydrogen
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
        case .mediumCar:
            return "중형차"
        case .largeCar:
            return "대형차"
        case .lowEmission:
            return "저공해 인증"
        case .electricHydrogen:
            return "전기/수소"
        case .hybrid:
            return "하이브리드"
        }
    }
}


