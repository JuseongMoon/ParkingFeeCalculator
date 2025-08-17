//
//  ParkingFeeWidget.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import WidgetKit
import SwiftUI

struct ParkingFeeWidget: Widget {
    let kind: String = "ParkingFeeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ParkingFeeWidgetTimelineProvider()) { entry in
            ParkingFeeWidgetView(data: entry.data)
        }
        .configurationDisplayName("주차비")
        .description("현재 주차비를 실시간으로 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

