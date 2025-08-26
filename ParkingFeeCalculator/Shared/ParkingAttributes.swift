
//
//  ParkingAttributes.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import ActivityKit
import Foundation

// 메인 앱에서 사용할 Live Activity Attributes
struct ParkingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var parkingLotName: String
        var initialFee: Int
        var initialMinutes: Int
        var additionalFee: Int
        var additionalMinutes: Int
        var freeMinutes: Int
        var additionalFreeMinutes: Int
        var maxFee: Int?
        var discountInfo: String?
    }
    
    var parkingLotName: String
}
