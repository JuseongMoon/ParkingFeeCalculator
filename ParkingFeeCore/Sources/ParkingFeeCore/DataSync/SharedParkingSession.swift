//
//  SharedParkingSession.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/24/25.
//

import Foundation

/// 앱, 위젯, 라이브 액티비티 간 공유되는 주차 세션 데이터
public struct SharedParkingSession: Codable, Equatable, Hashable {
    public let startTime: Date
    public let parkingLot: ParkingLotProfile
    public let vehicle: VehicleProfile
    public let driver: DriverProfile
    public let additionalFreeMinutes: Int
    
    // 현재 주차비 (계산됨)
    public var currentFee: Int {
        FeeCalculationService.shared.calculateFee(for: self).finalFee
    }
    
    // 현재 경과 시간 (초)
    public var elapsedTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    // 현재 경과 시간 (분)
    public var elapsedMinutes: Int {
        Int(elapsedTime / 60)
    }
    
    // 할인 정보
    public var discountInfo: String? {
        let result = FeeCalculationService.shared.calculateFee(for: self)
        return result.discountInfo
    }
    
    public init(
        startTime: Date,
        parkingLot: ParkingLotProfile,
        vehicle: VehicleProfile,
        driver: DriverProfile,
        additionalFreeMinutes: Int = 0
    ) {
        self.startTime = startTime
        self.parkingLot = parkingLot
        self.vehicle = vehicle
        self.driver = driver
        self.additionalFreeMinutes = additionalFreeMinutes
    }
}

// MARK: - UserDefaults 저장/불러오기를 위한 확장
public extension SharedParkingSession {
    /// UserDefaults에 저장 가능한 딕셔너리로 변환
    func toDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(self)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        return json ?? [:]
    }
    
    /// UserDefaults 딕셔너리에서 복원
    static func fromDictionary(_ dict: [String: Any]) throws -> SharedParkingSession {
        let data = try JSONSerialization.data(withJSONObject: dict)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        return try decoder.decode(SharedParkingSession.self, from: data)
    }
}