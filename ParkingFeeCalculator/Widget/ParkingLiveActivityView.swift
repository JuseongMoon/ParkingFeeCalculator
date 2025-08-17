//
//  ParkingLiveActivityView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import SwiftUI
import ActivityKit
import Foundation
import WidgetKit

struct ParkingLiveActivityLockView: View {
    let context: ActivityViewContext<ParkingLiveActivityAttributes>
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("주차비").font(.caption2)
                Text("\(context.state.currentFee)원")
                    .font(.title2).bold()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(context.state.parkingLotName).font(.caption2)
                Text(context.state.startedAt, style: .timer)
                    .font(.caption2).monospacedDigit()
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}

struct ParkingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingLiveActivityAttributes.self) { context in
            // 잠금화면/배너
            ParkingLiveActivityLockView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // expanded
                DynamicIslandExpandedRegion(.leading) {
                    Text("\(context.state.currentFee)원")
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startedAt, style: .timer)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.parkingLotName).lineLimit(1)
                }
            } compactLeading: {
                Text("P")
            } compactTrailing: {
                Text("\(context.state.currentFee)")
            } minimal: {
                Text("P")
            }
        }
    }
}
