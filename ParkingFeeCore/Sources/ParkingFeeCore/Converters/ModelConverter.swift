//
//  ModelConverter.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/26/25.
//

import Foundation

/// 모델 변환을 위한 유틸리티
public enum ModelConverter {
    
    /// SharedParkingSession을 딕셔너리로 변환
    public static func toDictionary(_ session: SharedParkingSession) throws -> [String: Any] {
        return try session.toDictionary()
    }
    
    /// 딕셔너리를 SharedParkingSession으로 변환
    public static func fromDictionary(_ dict: [String: Any]) throws -> SharedParkingSession {
        return try SharedParkingSession.fromDictionary(dict)
    }
    
    /// ParkingFeeResult를 간단한 정보로 변환
    public static func toSimpleInfo(_ result: ParkingFeeResult) -> [String: Any] {
        return [
            "baseFee": result.baseFee,
            "finalFee": result.finalFee,
            "discountAmount": result.discountAmount,
            "discountPercentage": result.discountPercentage,
            "discountInfo": result.discountInfo ?? "할인 없음"
        ]
    }
}