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

// Widget Extension용 ParkingAttributes 정의 (메인 앱과 호환)
public struct ParkingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var startTime: Date
        public var parkingLotName: String
        public var currentFee: Int
        public var discountInfo: String?
        public var nextChangeDate: Date?

        public init(startTime: Date, parkingLotName: String, currentFee: Int, discountInfo: String? = nil, nextChangeDate: Date? = nil) {
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

// MARK: - Time Formatting Extension
extension ParkingLiveActivityLockView {
    static func formatElapsedTime(_ startDate: Date) -> String {
        let now = Date()
        let elapsed = now.timeIntervalSince(startDate)
        let minutes = Int(elapsed / 60)
        
        if minutes < 1 {
            return "1분 미만"
        } else if minutes < 60 {
            return "\(minutes)분"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)시간"
            } else {
                return "\(hours)시간 \(remainingMinutes)분"
            }
        }
    }
}

struct ParkingLiveActivityLockView: View {
    let context: ActivityViewContext<ParkingAttributes>
    
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
                Text(ParkingLiveActivityLockView.formatElapsedTime(context.state.startTime))
                    .font(.caption2).monospacedDigit()
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}

struct ParkingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingAttributes.self) { context in
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
                    Text(ParkingLiveActivityLockView.formatElapsedTime(context.state.startTime))
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
