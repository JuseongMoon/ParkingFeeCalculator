
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
        var currentFee: Int
        var elapsedTime: TimeInterval
        var startTime: Date
        var discountInfo: String?
    }
    
    var parkingLotName: String
}
