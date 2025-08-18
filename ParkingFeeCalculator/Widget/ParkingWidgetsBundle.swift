//
//  ParkingWidgetsBundle.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import WidgetKit
import SwiftUI
import ActivityKit

@main
struct ParkingWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        ParkingFeeWidget()           // 기존 잠금화면 위젯
        ParkingFeeCalculatorWidgetLiveActivity()  // Live Activity
    }
}
