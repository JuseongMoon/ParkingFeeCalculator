//
//  ParkingLotDefaults.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import Foundation

// MARK: - 주차장 기본값 상수
struct ParkingLotDefaults {
    // 기본 요금 설정
    static let initialFee = 2000
    static let initialMinutes = 30
    static let additionalFee = 500
    static let additionalMinutes = 5
    static let maxFee = 20000
    static let freeMinutes = 0
    static let dailyMaxFee = 20000
    
    // 야간 요금 설정
    static let nightFlatFee = 0
    static let nightStartHour = 22
    static let nightEndHour = 7
    
    // 할인율 기본값
    static let mildDiscountPercentage: Double = 80
    static let severeDiscountPercentage: Double = 80
    static let nationalMeritDiscountPercentage: Double = 80
    static let exemplaryTaxpayerDiscountPercentage: Double = 100
    static let multiChildDiscountPercentage: Double = 50
    static let seniorDiscountPercentage: Double = 50
    
    // 차량 크기별 할인율
    static let lightCarDiscountPercentage: Double = 50
    static let normalCarDiscountPercentage: Double = 0
    static let largeCarDiscountPercentage: Double = 100
    
    // 친환경 차량 할인율
    static let electricDiscountPercentage: Double = 50
    static let hydrogenDiscountPercentage: Double = 50
    static let hybridDiscountPercentage: Double = 50
}
