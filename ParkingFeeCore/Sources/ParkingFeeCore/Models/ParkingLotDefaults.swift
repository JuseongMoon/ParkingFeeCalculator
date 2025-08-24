//
//  ParkingLotDefaults.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/16/25.
//

import Foundation

// MARK: - 주차장 기본값 상수
public struct ParkingLotDefaults {
    // 기본 요금 설정
    public static let initialFee = 2000
    public static let initialMinutes = 30
    public static let additionalFee = 500
    public static let additionalMinutes = 5
    public static let maxFee = 20000
    public static let freeMinutes = 0
    public static let dailyMaxFee = 20000
    
    // 야간 요금 설정
    public static let nightFlatFee = 0
    public static let nightStartHour = 22
    public static let nightEndHour = 7
    
    // 할인율 기본값
    public static let mildDiscountPercentage: Double = 80
    public static let severeDiscountPercentage: Double = 80
    public static let nationalMeritDiscountPercentage: Double = 80
    public static let exemplaryTaxpayerDiscountPercentage: Double = 100
    public static let multiChildDiscountPercentage: Double = 50
    public static let seniorDiscountPercentage: Double = 50
    
    // 차량 크기별 할인율
    public static let lightCarDiscountPercentage: Double = 50
    public static let normalCarDiscountPercentage: Double = 0
    public static let largeCarDiscountPercentage: Double = 100
    
    // 친환경 차량 할인율
    public static let electricDiscountPercentage: Double = 50
    public static let hydrogenDiscountPercentage: Double = 50
    public static let hybridDiscountPercentage: Double = 50
}