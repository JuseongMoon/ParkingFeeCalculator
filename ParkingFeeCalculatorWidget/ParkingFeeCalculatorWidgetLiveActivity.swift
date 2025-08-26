//
//  ParkingFeeCalculatorWidgetLiveActivity.swift
//  ParkingFeeCalculatorWidget
//
//  Created by 문주성 on 8/17/25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import ParkingFeeCore

// MARK: - UI Components
struct NavigationStyleTimeDisplay: View {
    let startTime: Date
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "parkingsign.circle.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(startTime, style: .timer)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("경과")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    private func formatNavigationTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        
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

struct LargeFeeDisplay: View {
    let fee: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(fee)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("원")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 2)
            }
        }
    }
}

struct CompactInfoBar: View {
    let parkingLotName: String
    let startTime: Date
    let discountInfo: String?
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
            
            Text(parkingLotName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            
            Text("|")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
            
            Text(formatStartTime(startTime))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            
            if let discount = discountInfo {
                Text("|")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                
                Text(discount)
                    .font(.system(size: 13))
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
    }
    
    private func formatStartTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date) + " 시작"
    }
}

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
    
    static func formatStartTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// Live Activity Attributes 정의
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

struct ParkingFeeCalculatorWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingAttributes.self) { context in
            // Lock screen/banner UI - Maps Style
            VStack(spacing: 12) {
                // 메인 정보 영역
                HStack {
                    // 왼쪽: Maps 스타일 시간 표시
                    NavigationStyleTimeDisplay(startTime: context.state.startTime)
                    
                    Spacer()
                    
                    // 오른쪽: 큰 요금 표시 (실시간 계산)
                    LargeFeeDisplay(fee: calculateCurrentFee(context.state))
                }
                
                // 하단 정보 바
                CompactInfoBar(
                    parkingLotName: context.attributes.parkingLotName,
                    startTime: context.state.startTime,
                    discountInfo: context.state.discountInfo
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background {
                // Maps 스타일 다크 그라데이션
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.3, blue: 0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .activityBackgroundTint(Color.blue.opacity(0.1))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // 확장된 상태 - 왼쪽: 출발 아이콘 + 주차장명
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "parkingsign.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                            Text("출발")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Text(context.attributes.parkingLotName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                
                // 확장된 상태 - 오른쪽: 경과 시간 표시
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.startTime, style: .timer)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("경과")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 확장된 상태 - 하단: 요금 + 시작시간 정보
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("현재 요금")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("\(calculateCurrentFee(context.state))원")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("시작 시간")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(ParkingFeeCalculatorWidgetLiveActivity.formatStartTime(context.state.startTime))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
            } compactLeading: {
                // 컴팩트 상태 - 왼쪽: 원형 주차 아이콘
                Image(systemName: "parkingsign.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                    
            } compactTrailing: {
                // 컴팩트 상태 - 오른쪽: 요금만 간단히
                Text("\(calculateCurrentFee(context.state))원")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
            } minimal: {
                // 최소 상태
                Image(systemName: "parkingsign.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
    }
}

// 요금 계산 함수 (순수 함수)
func calculateCurrentFee(_ state: ParkingAttributes.ContentState) -> Int {
    let elapsed = Date().timeIntervalSince(state.startTime)
    let totalFreeMinutes = state.freeMinutes + state.additionalFreeMinutes
    
    // 무료 시간 체크
    if elapsed <= TimeInterval(totalFreeMinutes * 60) {
        return 0
    }
    
    // 기본 시간 이후 계산
    let chargeableDuration = elapsed - TimeInterval(totalFreeMinutes * 60)
    let chargeableMinutes = Int(ceil(chargeableDuration / 60))
    
    if chargeableMinutes <= state.initialMinutes {
        return state.initialFee
    }
    
    // 추가 시간 계산
    let extraMinutes = chargeableMinutes - state.initialMinutes
    let additionalUnits = Int(ceil(Double(extraMinutes) / Double(state.additionalMinutes)))
    let extraFee = additionalUnits * state.additionalFee
    
    let totalFee = state.initialFee + extraFee
    
    // 최대 요금 제한
    if let maxFee = state.maxFee {
        return min(totalFee, maxFee)
    }
    
    return totalFee
}

#Preview("Notification", as: .content, using: ParkingAttributes(parkingLotName: "강남 지하주차장")) { 
   ParkingFeeCalculatorWidgetLiveActivity()
} contentStates: {
    ParkingAttributes.ContentState(
        startTime: Date(),
        parkingLotName: "강남 지하주차장",
        initialFee: 1000,
        initialMinutes: 30,
        additionalFee: 500,
        additionalMinutes: 10,
        freeMinutes: 10,
        additionalFreeMinutes: 0,
        maxFee: 10000,
        discountInfo: nil
    )
}
