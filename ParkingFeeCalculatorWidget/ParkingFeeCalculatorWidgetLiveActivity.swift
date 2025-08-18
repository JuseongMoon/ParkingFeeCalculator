//
//  ParkingFeeCalculatorWidgetLiveActivity.swift
//  ParkingFeeCalculatorWidget
//
//  Created by 문주성 on 8/17/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Live Activity Attributes 정의
struct ParkingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentFee: Int
        var elapsedTime: TimeInterval
    }
    
    var parkingLotName: String
}

struct ParkingFeeCalculatorWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingAttributes.self) { context in
            // Lock screen/banner UI
            VStack(alignment: .leading, spacing: 8) {
                Text("\(context.attributes.parkingLotName) 주차 중")
                    .font(.headline)
                
                HStack {
                    Text("경과 시간:")
                    Text(Date(timeIntervalSinceNow: -context.state.elapsedTime), style: .timer)
                }
                
                HStack {
                    Text("현재 요금:")
                    Text("\(context.state.currentFee)원")
                        .font(.title.bold())
                }
            }
            .padding()
            .activityBackgroundTint(Color.blue.opacity(0.3))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.parkingLotName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.currentFee)원")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("경과:")
                        Text(Date(timeIntervalSinceNow: -context.state.elapsedTime), style: .timer)
                    }
                }
            } compactLeading: {
                Image(systemName: "p.circle.fill")
            } compactTrailing: {
                Text("\(context.state.currentFee)원")
            } minimal: {
                Image(systemName: "p.circle.fill")
            }
            .keylineTint(Color.blue)
        }
    }
}

#Preview("Notification", as: .content, using: ParkingAttributes(parkingLotName: "테스트 주차장")) { 
   ParkingFeeCalculatorWidgetLiveActivity()
} contentStates: {
    ParkingAttributes.ContentState(currentFee: 5000, elapsedTime: 3600)
    ParkingAttributes.ContentState(currentFee: 10000, elapsedTime: 7200)
}
