//
//  ParkingFeeCalculator.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import Foundation

struct ParkingFeeCalculator: Codable, Identifiable {
    let id = UUID()
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
    var createdAt: Date
    var updatedAt: Date
    
    init(
        initialFee: Int = 1000,
        initialMinutes: Int = 60,
        additionalFee: Int = 500,
        additionalMinutes: Int = 30,
        maxFee: Int? = nil,
        freeMinutes: Int = 0,
        dailyMaxFee: Int? = nil,
        nightFlatFee: Int? = nil,
        nightStartHour: Int? = nil,
        nightEndHour: Int? = nil
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
    
    func getVehicleMultiplier(for vehicleSize: VehicleSize) -> Double {
        return vehicleSize.defaultRateMultiplier
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
    /// - Returns: 계산된 주차비 결과
    func calculateFee(
        duration: TimeInterval,
        vehicleProfile: VehicleProfile,
        driverProfile: DriverProfile,
        specialConditionDiscounts: SpecialConditionDiscounts,
        startTime: Date = Date()
    ) -> ParkingFeeResult {
        // 기본 주차비 계산
        let baseFee = calculateBaseFee(duration: duration)
        
        // 차량 크기 배수 적용
        let vehicleMultiplier = getVehicleMultiplier(for: vehicleProfile.vehicleSize)
        var totalFee = Int(Double(baseFee) * vehicleMultiplier)
        
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
            finalFee = Int(Double(totalFee) * (1.0 - discount.percentage / 100.0))
            appliedDiscount = discount
        }
        
        // 일일 최대 요금 제한
        if let dailyMaxFee = self.dailyMaxFee {
            finalFee = min(finalFee, dailyMaxFee)
        }
        
        return ParkingFeeResult(
            baseFee: baseFee,
            vehicleMultiplier: vehicleMultiplier,
            totalFeeBeforeDiscount: totalFee,
            appliedDiscount: appliedDiscount,
            finalFee: finalFee,
            applicableDiscounts: applicableDiscounts
        )
    }
    
    /// 기본 주차비를 계산합니다 (차량 크기 배수와 할인 제외)
    private func calculateBaseFee(duration: TimeInterval) -> Int {
        // 무료 시간 체크
        if duration <= TimeInterval(freeMinutes * 60) {
            return 0
        }
        
        // 야간 요금 체크
        if isNightTime(), let nightFlatFee = nightFlatFee {
            return nightFlatFee
        }
        
        // 기본 시간 이후 계산
        let chargeableDuration = duration - TimeInterval(freeMinutes * 60)
        let chargeableMinutes = Int(chargeableDuration / 60)
        
        if chargeableMinutes <= initialMinutes {
            return initialFee
        }
        
        // 추가 시간 계산
        let extraMinutes = chargeableMinutes - initialMinutes
        let additionalUnits = Int(ceil(Double(extraMinutes) / Double(self.additionalMinutes)))
        let extraFee = additionalUnits * self.additionalFee
        
        return initialFee + extraFee
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
                    name: "일반차",
                    percentage: discountPercentage,
                    type: .vehicle
                ))
            }
        case .medium:
            if let discountPercentage = specialConditionDiscounts.mediumCarDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "중형차",
                    percentage: discountPercentage,
                    type: .vehicle
                ))
            }
        case .large:
            if let discountPercentage = specialConditionDiscounts.largeCarDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "대형차",
                    percentage: discountPercentage,
                    type: .vehicle
                ))
            }
        }
        
        // 친환경 차량 할인 확인
        if vehicleProfile.isLowEmission {
            if let discountPercentage = specialConditionDiscounts.lowEmissionDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "저공해 인증",
                    percentage: discountPercentage,
                    type: .environmental
                ))
            }
        }
        
        if vehicleProfile.isElectricHydrogen {
            if let discountPercentage = specialConditionDiscounts.electricHydrogenDiscountPercentage {
                applicableDiscounts.append(DiscountInfo(
                    name: "전기/수소",
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
    let vehicleMultiplier: Double
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
