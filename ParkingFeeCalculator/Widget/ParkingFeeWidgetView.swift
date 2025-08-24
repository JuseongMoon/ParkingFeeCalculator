//
//  ParkingFeeWidgetView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import SwiftUI
import WidgetKit

// MARK: - Widget UI Components
struct WidgetNavigationTimeDisplay: View {
    let elapsedTime: TimeInterval
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "parkingsign.circle.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formatNavigationTime(elapsedTime))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("경과")
                    .font(.system(size: 16, weight: .medium))
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

struct WidgetLargeFeeDisplay: View {
    let fee: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(fee)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("원")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 2)
            }
        }
    }
}

struct WidgetCompactInfoBar: View {
    let parkingLotName: String
    let startTime: Date
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.yellow)
            
            Text(parkingLotName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Text("|")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
            
            Text(formatStartTime(startTime))
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
    
    private func formatStartTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date) + " 시작"
    }
}

struct ParkingFeeWidgetView: View {
    let data: SharedParkingData
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        Group {
            if data.isParkingActive {
                switch widgetFamily {
                case .systemSmall:
                    smallWidgetActiveView
                case .systemMedium:
                    mediumWidgetActiveView
                default:
                    smallWidgetActiveView
                }
            } else {
                switch widgetFamily {
                case .systemSmall:
                    smallWidgetInactiveView
                case .systemMedium:
                    mediumWidgetInactiveView
                default:
                    smallWidgetInactiveView
                }
            }
        }
        .containerBackground(for: .widget) {
            // Maps 스타일 다크 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.3, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Small Widget Views
    private var smallWidgetActiveView: some View {
        VStack(spacing: 12) {
            // 현재 요금을 중심으로
            WidgetLargeFeeDisplay(fee: data.currentFee)
            
            // 경과시간
            let elapsedTime = Date().timeIntervalSince(data.parkingStartTime)
            WidgetNavigationTimeDisplay(elapsedTime: elapsedTime)
                .scaleEffect(0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }
    
    private var smallWidgetInactiveView: some View {
        VStack(spacing: 12) {
            Image(systemName: "parkingsign.circle.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            Text("주차 대기중")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }
    
    // MARK: - Medium Widget Views
    private var mediumWidgetActiveView: some View {
        VStack(spacing: 8) {
            // 메인 정보 영역
            HStack(alignment: .top) {
                // 왼쪽: 경과 시간
                let elapsedTime = Date().timeIntervalSince(data.parkingStartTime)
                WidgetNavigationTimeDisplay(elapsedTime: elapsedTime)
                    .scaleEffect(0.9)
                
                Spacer()
                
                // 오른쪽: 현재 요금
                WidgetLargeFeeDisplay(fee: data.currentFee)
            }
            
            Spacer()
            
            // 하단 정보 바
            WidgetCompactInfoBar(
                parkingLotName: data.parkingLotName,
                startTime: data.parkingStartTime
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var mediumWidgetInactiveView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "parkingsign.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("주차 대기중")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("주차장 선택 후")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                Text("타이머 시작")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

