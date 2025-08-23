//
//  ParkingFeeCalculatorWidgetLiveActivity.swift
//  ParkingFeeCalculatorWidget
//
//  Created by 문주성 on 8/17/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Time Formatting Helper
extension ParkingFeeCalculatorWidgetLiveActivity {
    static func formatElapsedTime(_ elapsedSeconds: TimeInterval) -> String {
        let minutes = Int(elapsedSeconds / 60)
        
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
            HStack(spacing: 16) {
                // 왼쪽 영역 - 주차장 정보
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                        Text("주차 중")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(context.attributes.parkingLotName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 가운데 영역 - 경과 시간
                VStack(alignment: .center, spacing: 2) {
                    Text("경과 시간")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(ParkingFeeCalculatorWidgetLiveActivity.formatElapsedTime(context.state.elapsedTime))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
                
                // 오른쪽 영역 - 요금
                VStack(alignment: .trailing, spacing: 2) {
                    Text("현재 요금")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(context.state.currentFee)원")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .blue.opacity(0.1), radius: 8, x: 0, y: 2)
            }
            .activityBackgroundTint(Color.blue.opacity(0.05))
            .activitySystemActionForegroundColor(.blue)

        } dynamicIsland: { context in
            DynamicIsland {
                // 확장된 상태 - 왼쪽
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                            Text("주차장")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text(context.attributes.parkingLotName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                
                // 확장된 상태 - 오른쪽
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("현재 요금")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(context.state.currentFee)원")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }
                
                // 확장된 상태 - 하단
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("경과:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(ParkingFeeCalculatorWidgetLiveActivity.formatElapsedTime(context.state.elapsedTime))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
            } compactLeading: {
                // 컴팩트 상태 - 왼쪽
                Image(systemName: "car.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    
            } compactTrailing: {
                // 컴팩트 상태 - 오른쪽
                HStack(spacing: 2) {
                    Text("\(context.state.currentFee)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("원")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                
            } minimal: {
                // 최소 상태
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 20, height: 20)
                    Image(systemName: "car.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .keylineTint(.blue)
        }
    }
}

#Preview("Notification", as: .content, using: ParkingAttributes(parkingLotName: "강남 지하주차장")) { 
   ParkingFeeCalculatorWidgetLiveActivity()
} contentStates: {
    ParkingAttributes.ContentState(currentFee: 1500, elapsedTime: 30)    // 30초 - "1분 미만"
    ParkingAttributes.ContentState(currentFee: 3000, elapsedTime: 900)   // 15분
    ParkingAttributes.ContentState(currentFee: 8500, elapsedTime: 5400)  // 1시간 30분
}
