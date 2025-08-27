//
//  ParkingAttributes.swift
//  ParkingShared
//
//  Created by Claude Code on 8/27/25.
//

import ActivityKit
import Foundation

// Live Activity Attributes - ActivityKit 의존성을 위한 별도 모듈
public struct ParkingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var startTime: Date
        public var parkingLotName: String
        public var currentFee: Int  // 계산 완료된 요금
        public var discountInfo: String?
        public var nextChangeDate: Date?  // 다음 요금 변경 시점
        
        public init(
            startTime: Date,
            parkingLotName: String,
            currentFee: Int,
            discountInfo: String? = nil,
            nextChangeDate: Date? = nil
        ) {
            self.startTime = startTime
            self.parkingLotName = parkingLotName
            self.currentFee = currentFee
            self.discountInfo = discountInfo
            self.nextChangeDate = nextChangeDate
        }
    }
    
    public var parkingLotName: String
    
    public init(parkingLotName: String) {
        self.parkingLotName = parkingLotName
    }
}