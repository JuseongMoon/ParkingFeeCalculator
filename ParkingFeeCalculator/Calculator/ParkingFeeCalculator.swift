//
//  ParkingFeeCalculator.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import Foundation

// 야간 요금 타입 enum
enum NightRateType: String, Codable, CaseIterable {
    case flat = "flat"           // 정액 요금
    case percentage = "percentage" // 퍼센트 할인
    
    var displayName: String {
        switch self {
        case .flat:
            return "정액 요금"
        case .percentage:
            return "할인율 적용"
        }
    }
}

// 시간 구간별 차등 요금 구조체
struct TimeBasedPricingTier: Codable, Identifiable {
    var id: UUID = UUID()
    var thresholdMinutes: Int  // 기준 시간 (분)
    var feePerUnit: Int        // 단위당 요금
    var unitMinutes: Int       // 단위 시간 (분)
    
    init(thresholdMinutes: Int, feePerUnit: Int, unitMinutes: Int) {
        self.thresholdMinutes = thresholdMinutes
        self.feePerUnit = feePerUnit
        self.unitMinutes = unitMinutes
    }
}

struct ParkingFeeCalculator: Codable, Identifiable {
    var id: UUID = UUID()
    var initialFee: Int
    var initialMinutes: Int
    var additionalFee: Int
    var additionalMinutes: Int
    var maxFee: Int?
    var freeMinutes: Int
    var dailyMaxFee: Int?
    var nightFlatFee: Int?
    var nightStartHour: Int?
    var nightEndHour: Int?
    var nightRateType: NightRateType
    var nightDiscountPercentage: Double?
    var useTimeBasedPricing: Bool
    var pricingTiers: [TimeBasedPricingTier]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        initialFee: Int = ParkingLotDefaults.initialFee,
        initialMinutes: Int = ParkingLotDefaults.initialMinutes,
        additionalFee: Int = ParkingLotDefaults.additionalFee,
        additionalMinutes: Int = ParkingLotDefaults.additionalMinutes,
        maxFee: Int? = nil,
        freeMinutes: Int = ParkingLotDefaults.freeMinutes,
        dailyMaxFee: Int? = nil,
        nightFlatFee: Int? = nil,
        nightStartHour: Int? = nil,
        nightEndHour: Int? = nil,
        nightRateType: NightRateType = .flat,
        nightDiscountPercentage: Double? = nil,
        useTimeBasedPricing: Bool = false,
        pricingTiers: [TimeBasedPricingTier] = []
    ) {
        self.initialFee = initialFee
        self.initialMinutes = initialMinutes
        self.additionalFee = additionalFee
        self.additionalMinutes = additionalMinutes
        self.maxFee = maxFee
        self.freeMinutes = freeMinutes
        self.dailyMaxFee = dailyMaxFee
        self.nightFlatFee = nightFlatFee
        self.nightStartHour = nightStartHour
        self.nightEndHour = nightEndHour
        self.nightRateType = nightRateType
        self.nightDiscountPercentage = nightDiscountPercentage
        self.useTimeBasedPricing = useTimeBasedPricing
        self.pricingTiers = pricingTiers
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - ParkingFeeCalculator Extensions
extension ParkingFeeCalculator {
    var isProfileComplete: Bool {
        return initialFee > 0 && initialMinutes > 0 && additionalFee > 0 && additionalMinutes > 0
    }
    
    var hasNightRate: Bool {
        return nightFlatFee != nil && nightStartHour != nil && nightEndHour != nil
    }
    
    var hasDailyMax: Bool {
        return dailyMaxFee != nil
    }
    
    var hasMaxFee: Bool {
        return maxFee != nil
    }
    

    
    func isNightTime() -> Bool {
        guard let startHour = nightStartHour, let endHour = nightEndHour else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        if startHour <= endHour {
            return currentHour >= startHour && currentHour < endHour
        } else {
            // 자정을 넘어가는 경우 (예: 22시~06시)
            return currentHour >= startHour || currentHour < endHour
        }
    }
    
    // MARK: - 주차비 계산 메서드
    
    /// 주차비를 계산합니다. 할인을 적용하여 최종 요금을 반환합니다.
    /// - Parameters:
    ///   - duration: 주차 시간 (초)
    ///   - vehicleProfile: 차량 프로필
    ///   - driverProfile: 운전자 프로필
    ///   - specialConditionDiscounts: 특별 조건 할인 정보
    ///   - startTime: 주차 시작 시간 (기본값: 현재 시간)
    ///   - additionalFreeMinutes: 추가 무료시간 (분, 기본값: 0)
    /// - Returns: 계산된 주차비 결과
    func calculateFee(
        duration: TimeInterval,
        vehicleProfile: VehicleProfile,
        driverProfile: DriverProfile,
        specialConditionDiscounts: SpecialConditionDiscounts,
        startTime: Date = Date(),
        additionalFreeMinutes: Int = 0
    ) -> ParkingFeeResult {
        // 기본 주차비 계산 (추가 무료시간 반영)
        let baseFee = calculateBaseFee(duration: duration, additionalFreeMinutes: additionalFreeMinutes)
        
        var totalFee = baseFee
        
        // 최대 요금 제한 (할인 적용 전)
        if let maxFee = self.maxFee {
            totalFee = min(totalFee, maxFee)
        }
        
        // 적용 가능한 할인 찾기
        let applicableDiscounts = findApplicableDiscounts(
            vehicleProfile: vehicleProfile,
            driverProfile: driverProfile,
            specialConditionDiscounts: specialConditionDiscounts
        )
        
        // 가장 높은 할인율 찾기
        let bestDiscount = findBestDiscount(from: applicableDiscounts)
        
        // 할인 적용
        var finalFee = totalFee
        var appliedDiscount: DiscountInfo?
        
        if let discount = bestDiscount {
            // 부동소수점 정밀도 문제를 해결하기 위해 반올림 사용
            let discountedAmount = Double(totalFee) * (1.0 - discount.percentage / 100.0)
            finalFee = Int(round(discountedAmount))
            appliedDiscount = discount
        }
        
        // 일일 최대 요금 제한
        if let dailyMaxFee = self.dailyMaxFee {
            finalFee = min(finalFee, dailyMaxFee)
        }
        
        return ParkingFeeResult(
            baseFee: baseFee,
            totalFeeBeforeDiscount: totalFee,
            appliedDiscount: appliedDiscount,
            finalFee: finalFee,
            applicableDiscounts: applicableDiscounts
        )
    }
    
    /// 기본 주차비를 계산합니다 (차량 크기 배수와 할인 제외)
    private func calculateBaseFee(duration: TimeInterval, additionalFreeMinutes: Int = 0) -> Int {
        // 총 무료 시간 계산
        let totalFreeMinutes = freeMinutes + additionalFreeMinutes
        
        // 무료 시간 체크
        if duration <= TimeInterval(totalFreeMinutes * 60) {
            return 0
        }
        
        // 기본 시간 이후 계산
        let chargeableDuration = duration - TimeInterval(totalFreeMinutes * 60)
        let chargeableMinutes = Int(ceil(chargeableDuration / 60))
        
        // 야간 요금 체크
        if isNightTime() {
            return calculateNightRateFee(chargeableMinutes: chargeableMinutes)
        }
        
        // 시간 구간별 요금 계산
        if useTimeBasedPricing && !pricingTiers.isEmpty {
            return calculateTimeBasedFee(chargeableMinutes: chargeableMinutes)
        }
        
        // 기존 단일 요금 체계 계산
        return calculateSimpleFee(chargeableMinutes: chargeableMinutes)
    }
    
    /// 시간 구간별 차등 요금 계산
    private func calculateTimeBasedFee(chargeableMinutes: Int) -> Int {
        var totalFee = 0
        var remainingMinutes = chargeableMinutes
        
        // 초기 요금 처리
        if remainingMinutes > 0 {
            let initialUnits = min(remainingMinutes, initialMinutes)
            if initialUnits > 0 {
                totalFee = initialFee
                remainingMinutes -= initialMinutes
            }
        }
        
        if remainingMinutes <= 0 {
            return totalFee
        }
        
        // 구간별로 정렬된 pricing tiers 적용
        let sortedTiers = pricingTiers.sorted { $0.thresholdMinutes < $1.thresholdMinutes }
        var currentThreshold = initialMinutes
        
        for tier in sortedTiers {
            if remainingMinutes <= 0 { break }
            
            // 현재 구간에서 처리할 시간 계산
            let minutesToProcess: Int
            if currentThreshold < tier.thresholdMinutes {
                // 현재 threshold부터 다음 tier threshold까지는 기본 추가요금으로 계산
                minutesToProcess = min(remainingMinutes, tier.thresholdMinutes - currentThreshold)
                if minutesToProcess > 0 {
                    let units = Int(ceil(Double(minutesToProcess) / Double(additionalMinutes)))
                    totalFee += units * additionalFee
                    remainingMinutes -= minutesToProcess
                }
                currentThreshold = tier.thresholdMinutes
            }
            
            // tier threshold 이후는 해당 tier의 요금으로 계산
            if remainingMinutes > 0 {
                // 다음 tier가 있다면 그 threshold까지, 없다면 모든 남은 시간
                let nextThreshold = sortedTiers.first(where: { $0.thresholdMinutes > tier.thresholdMinutes })?.thresholdMinutes ?? Int.max
                let tierMinutes = min(remainingMinutes, nextThreshold - tier.thresholdMinutes)
                
                if tierMinutes > 0 {
                    let units = Int(ceil(Double(tierMinutes) / Double(tier.unitMinutes)))
                    totalFee += units * tier.feePerUnit
                    remainingMinutes -= tierMinutes
                    currentThreshold = tier.thresholdMinutes + tierMinutes
                }
            }
        }
        
        // 마지막 tier 이후 남은 시간이 있다면 마지막 tier 요금으로 계산
        if remainingMinutes > 0, let lastTier = sortedTiers.last {
            let units = Int(ceil(Double(remainingMinutes) / Double(lastTier.unitMinutes)))
            totalFee += units * lastTier.feePerUnit
        }
        
        return totalFee
    }
    
    /// 기존 단일 요금 체계 계산
    private func calculateSimpleFee(chargeableMinutes: Int) -> Int {
        if chargeableMinutes <= initialMinutes {
            return initialFee
        }
        
        // 추가 시간 계산
        let extraMinutes = chargeableMinutes - initialMinutes
        let additionalUnits = Int(ceil(Double(extraMinutes) / Double(self.additionalMinutes)))
        let extraFee = additionalUnits * self.additionalFee
        
        return initialFee + extraFee
    }
    
    /// 야간 요금을 계산합니다
    private func calculateNightRateFee(chargeableMinutes: Int) -> Int {
        switch nightRateType {
        case .flat:
            // 정액 요금 적용
            guard let flatFee = nightFlatFee else {
                // 야간 정액 요금이 설정되지 않은 경우 일반 요금으로 계산
                return useTimeBasedPricing && !pricingTiers.isEmpty ? 
                    calculateTimeBasedFee(chargeableMinutes: chargeableMinutes) :
                    calculateSimpleFee(chargeableMinutes: chargeableMinutes)
            }
            return flatFee
            
        case .percentage:
            // 할인율 적용
            guard let discountPercentage = nightDiscountPercentage else {
                // 할인율이 설정되지 않은 경우 일반 요금으로 계산
                return useTimeBasedPricing && !pricingTiers.isEmpty ? 
                    calculateTimeBasedFee(chargeableMinutes: chargeableMinutes) :
                    calculateSimpleFee(chargeableMinutes: chargeableMinutes)
            }
            
            // 일반 요금 계산 후 할인 적용
            let normalFee = useTimeBasedPricing && !pricingTiers.isEmpty ? 
                calculateTimeBasedFee(chargeableMinutes: chargeableMinutes) :
                calculateSimpleFee(chargeableMinutes: chargeableMinutes)
            
            let discountedAmount = Double(normalFee) * (1.0 - discountPercentage / 100.0)
            return Int(round(discountedAmount))
        }
    }
    
    /// 적용 가능한 할인들을 찾습니다
    private func findApplicableDiscounts(
        vehicleProfile: VehicleProfile,
        driverProfile: DriverProfile,
        specialConditionDiscounts: SpecialConditionDiscounts
    ) -> [DiscountInfo] {
        var applicableDiscounts: [DiscountInfo] = []
        
        // 운전자 관련 할인 확인
        if driverProfile.isDisabled, let level = driverProfile.disabilityLevel {
            switch level {
            case .mild:
                if let discountPercentage = specialConditionDiscounts.mildDiscountPercentage {
                    applicableDiscounts.append(DiscountInfo(
                        name: "경증 장애인",
                        percentage: discountPercentage,
                        type: .driver
                    ))
                }
            case .severe:
                if let discountPercentage = specialConditionDiscounts.severeDiscountPercentage {
                    applicableDiscounts.append(DiscountInfo(
                        name: "중증 장애인",
                        percentage: discountPercentage,
                        type: .driver
                    ))
                }
            }
        }
        
        if driverProfile.isNationalMerit {
            if let discountPercentage = specialConditionDiscounts.nationalMeritDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "국가유공자",
                    percentage: discountPercentage,
                    type: .driver
                ))
            }
        }
        
        if driverProfile.isExemplaryTaxpayer {
            if let discountPercentage = specialConditionDiscounts.exemplaryTaxpayerDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "모범납세자",
                    percentage: discountPercentage,
                    type: .driver
                ))
            }
        }
        
        if driverProfile.isMultiChild {
            if let discountPercentage = specialConditionDiscounts.multiChildDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "다자녀",
                    percentage: discountPercentage,
                    type: .driver
                ))
            }
        }
        
        if driverProfile.isSenior {
            if let discountPercentage = specialConditionDiscounts.seniorDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "고령자",
                    percentage: discountPercentage,
                    type: .driver
                ))
            }
        }
        
        // 차량 관련 할인 확인
        switch vehicleProfile.vehicleSize {
        case .light:
            if let discountPercentage = specialConditionDiscounts.lightCarDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "경차",
                    percentage: discountPercentage,
                    type: .vehicle
                ))
            }
        case .normal:
            if let discountPercentage = specialConditionDiscounts.normalCarDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "일반",
                    percentage: discountPercentage,
                    type: .vehicle
                ))
            }
        case .large:
            if let discountPercentage = specialConditionDiscounts.largeCarDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "대형",
                    percentage: discountPercentage,
                    type: .vehicle
                ))
            }
        }
        
        // 친환경 차량 할인 확인
        if vehicleProfile.isElectric {
            if let discountPercentage = specialConditionDiscounts.electricDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "전기차",
                    percentage: discountPercentage,
                    type: .environmental
                ))
            }
        }
        
        if vehicleProfile.isHydrogen {
            if let discountPercentage = specialConditionDiscounts.hydrogenDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "수소차",
                    percentage: discountPercentage,
                    type: .environmental
                ))
            }
        }
        
        if vehicleProfile.isHybrid {
            if let discountPercentage = specialConditionDiscounts.hybridDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "하이브리드",
                    percentage: discountPercentage,
                    type: .environmental
                ))
            }
        }
        
        return applicableDiscounts
    }
    
    /// 가장 높은 할인율을 가진 할인을 찾습니다
    private func findBestDiscount(from discounts: [DiscountInfo]) -> DiscountInfo? {
        guard !discounts.isEmpty else { return nil }
        
        return discounts.max { discount1, discount2 in
            discount1.percentage < discount2.percentage
        }
    }
}

// MARK: - 결과 타입들
struct ParkingFeeResult {
    let baseFee: Int
    let totalFeeBeforeDiscount: Int
    let appliedDiscount: DiscountInfo?
    let finalFee: Int
    let applicableDiscounts: [DiscountInfo]
    
    var discountAmount: Int {
        return totalFeeBeforeDiscount - finalFee
    }
    
    var discountPercentage: Double {
        guard totalFeeBeforeDiscount > 0 else { return 0.0 }
        return Double(discountAmount) / Double(totalFeeBeforeDiscount) * 100.0
    }
    
    var appliedDiscountDescription: String {
        guard let discount = appliedDiscount else { return "할인 없음" }
        return "\(discount.name) (-\(Int(discount.percentage))%)"
    }
    
    var applicableDiscountsDescription: String {
        guard !applicableDiscounts.isEmpty else { return "적용 가능한 할인 없음" }
        
        let descriptions = applicableDiscounts.map { discount in
            "\(discount.name) \(Int(discount.percentage))%"
        }
        
        return descriptions.joined(separator: ", ")
    }
    
    var discountInfo: String? {
        if applicableDiscounts.isEmpty {
            return nil
        } else if applicableDiscounts.count == 1 {
            return "적용된 할인: \(applicableDiscounts[0].name) \(Int(applicableDiscounts[0].percentage))%"
        } else {
            return "적용 가능: \(applicableDiscounts.map { "\($0.name) \(Int($0.percentage))%" }.joined(separator: ", "))"
        }
    }
}

struct DiscountInfo {
    let name: String
    let percentage: Double
    let type: DiscountType
    
    enum DiscountType {
        case driver
        case vehicle
        case environmental
    }
}
