//
//  ParkingFeeCalculatorWidget.swift
//  ParkingFeeCalculatorWidget
//
//  Created by 문주성 on 8/17/25.
//

import WidgetKit
import SwiftUI
import ParkingFeeCore

struct ParkingWidgetEntry: TimelineEntry {
    let date: Date
    let session: SharedParkingSession?
    let currentFee: Int
    let nextChangeTime: Date?
}

struct ParkingWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ParkingWidgetEntry {
        ParkingWidgetEntry(
            date: Date(),
            session: nil,
            currentFee: 0,
            nextChangeTime: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ParkingWidgetEntry) -> ()) {
        let session = ParkingSessionManager.shared.currentSession()
        let currentFee = session?.currentFee ?? 0
        let nextChange = session.flatMap { 
            FeeCalculationUtilities.nextFeeChangeTime(for: $0)
        }
        
        let entry = ParkingWidgetEntry(
            date: Date(),
            session: session,
            currentFee: currentFee,
            nextChangeTime: nextChange
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        guard let session = ParkingSessionManager.shared.currentSession() else {
            // 세션이 없으면 빈 엔트리
            let entry = ParkingWidgetEntry(
                date: Date(),
                session: nil,
                currentFee: 0,
                nextChangeTime: nil
            )
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300))) // 5분 후 재확인
            completion(timeline)
            return
        }
        
        var entries: [ParkingWidgetEntry] = []
        let now = Date()
        
        // 현재 엔트리
        let currentFee = session.currentFee
        entries.append(ParkingWidgetEntry(
            date: now,
            session: session,
            currentFee: currentFee,
            nextChangeTime: FeeCalculationUtilities.nextFeeChangeTime(for: session, after: now)
        ))
        
        // 향후 6시간 동안의 변경점들 (최대 20개)
        let changePoints = FeeCalculationUtilities.getAllSignificantChangePoints(
            for: session,
            maxDuration: 21600 // 6시간
        ).prefix(20)
        
        for changeTime in changePoints {
            if changeTime > now {
                let fee = FeeCalculationService.shared.calculateFee(
                    for: session,
                    at: changeTime
                ).finalFee
                
                let nextChange = FeeCalculationUtilities.nextFeeChangeTime(
                    for: session,
                    after: changeTime.addingTimeInterval(1)
                )
                
                entries.append(ParkingWidgetEntry(
                    date: changeTime,
                    session: session,
                    currentFee: fee,
                    nextChangeTime: nextChange
                ))
            }
        }
        
        // 타임라인 정책: 마지막 엔트리 시간 또는 6시간 후
        let lastDate = entries.last?.date ?? now
        let reloadDate = min(lastDate.addingTimeInterval(60), now.addingTimeInterval(21600))
        
        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}

struct ParkingFeeCalculatorWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: ParkingWidgetProvider.Entry
    
    var body: some View {
        if let session = entry.session {
            VStack(alignment: .leading, spacing: 8) {
                // 주차장 이름
                HStack {
                    Image(systemName: "parkingsign.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    Text(session.parkingLot.name)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                }
                
                // 경과 시간 (자동 갱신)
                HStack {
                    Text("경과")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(session.startTime, style: .timer)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                // 현재 요금
                HStack {
                    Text("요금")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(entry.currentFee)원")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                
                // 할인 정보 (있을 경우)
                if let discountInfo = session.discountInfo {
                    Text(discountInfo)
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .lineLimit(1)
                }
            }
            .padding()
        } else {
            // 세션이 없을 때
            VStack {
                Image(systemName: "parkingsign.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("주차 정보 없음")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct ParkingFeeCalculatorWidget: Widget {
    let kind: String = "ParkingFeeCalculatorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ParkingWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                ParkingFeeCalculatorWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                ParkingFeeCalculatorWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("주차 요금 계산기")
        .description("현재 주차 요금과 경과 시간을 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ParkingFeeCalculatorWidget()
} timeline: {
    ParkingWidgetEntry(date: .now, session: nil, currentFee: 0, nextChangeTime: nil)
}
