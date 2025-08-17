//
//  ParkingLiveActivityAttributes.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import ActivityKit
import Foundation

struct ParkingLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentFee: Int
        var startedAt: Date
        var parkingLotName: String
    }
    
    // 고정 속성(활동 시작 시 결정)
    var initialFee: Int
    var additionalFee: Int
    var additionalMinutes: Int
}
