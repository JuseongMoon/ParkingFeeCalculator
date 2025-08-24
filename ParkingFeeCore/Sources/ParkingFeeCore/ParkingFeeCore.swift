//
//  ParkingFeeCore.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/24/25.
//

import Foundation

// MARK: - Public API 
// 이 파일은 패키지의 공개 API를 정의합니다

// Models - 모든 모델들이 각각의 파일에서 public으로 선언되어 있음
// - ParkingFeeCalculator
// - ParkingLotProfile  
// - VehicleProfile
// - DriverProfile
// - ParkingLotDefaults
// - SpecialConditionDiscounts
// - ParkingFeeResult
// - DiscountInfo
// - TimeBasedPricingTier
// - NightRateType

// Services - 핵심 서비스들
// - FeeCalculationService
// - ParkingSessionManager

// Data Sync - 데이터 동기화
// - SharedParkingSession
// - DataChangeNotifier

// 패키지 버전 정보
public enum ParkingFeeCoreVersion {
    public static let version = "1.0.0"
    public static let buildNumber = 1
}