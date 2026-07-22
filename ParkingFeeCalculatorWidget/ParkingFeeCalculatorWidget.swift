//
//  ParkingFeeCalculatorWidget.swift
//  ParkingFeeCalculatorWidget
//
//  Created by 문주성 on 8/17/25.
//

import WidgetKit
import SwiftUI

// 위젯 전용 데이터 구조
struct SharedParkingData: Codable {
    let isParkingActive: Bool
    let currentFee: Int
    let parkingStartTime: Date
    let parkingLotName: String
    let discountInfo: String?

    init(isParkingActive: Bool = false, currentFee: Int = 0, parkingStartTime: Date = Date(), parkingLotName: String = "", discountInfo: String? = nil) {
        self.isParkingActive = isParkingActive
        self.currentFee = currentFee
        self.parkingStartTime = parkingStartTime
        self.parkingLotName = parkingLotName
        self.discountInfo = discountInfo
    }
}

struct ParkingWidgetEntry: TimelineEntry {
    let date: Date
    let data: SharedParkingData
}

struct ParkingWidgetProvider: TimelineProvider {
    private let userDefaults = UserDefaults(suiteName: "group.com.ScienceFiction.ParkingFeeCalculator")

    func placeholder(in context: Context) -> ParkingWidgetEntry {
        ParkingWidgetEntry(
            date: Date(),
            data: SharedParkingData()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ParkingWidgetEntry) -> ()) {
        let entry = ParkingWidgetEntry(
            date: Date(),
            data: loadParkingData()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ParkingWidgetEntry>) -> ()) {
        let currentData = loadParkingData()

        let entry = ParkingWidgetEntry(
            date: Date(),
            data: currentData
        )

        // 주차 상태에 따른 업데이트 빈도 조절
        let updateInterval: Int = currentData.isParkingActive ? 1 : 5 // 주차 중: 1분, 대기 중: 5분
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: updateInterval, to: Date()) ?? Date()
        let timeline = Timeline<ParkingWidgetEntry>(entries: [entry], policy: .after(nextUpdateDate))

        completion(timeline)
    }

    // 간단한 UserDefaults 기반 데이터 로딩
    private func loadParkingData() -> SharedParkingData {
        guard let data = userDefaults?.data(forKey: "sharedParkingData"),
              let sharedData = try? JSONDecoder().decode(SharedParkingData.self, from: data) else {
            return SharedParkingData()
        }
        return sharedData
    }
}

struct ParkingFeeCalculatorWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: ParkingWidgetProvider.Entry

    var body: some View {
        if entry.data.isParkingActive {
            VStack(alignment: .leading, spacing: 8) {
                // 주차장 이름
                HStack {
                    Image(systemName: "parkingsign.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    Text(entry.data.parkingLotName)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                }

                // 경과 시간 (자동 갱신)
                HStack {
                    Text("경과")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(entry.data.parkingStartTime, style: .timer)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                }

                // 현재 요금
                HStack {
                    Text("요금")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(entry.data.currentFee)원")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }

                // 할인 정보 (있을 경우)
                if let discountInfo = entry.data.discountInfo {
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
    ParkingWidgetEntry(
        date: .now,
        data: SharedParkingData(
            isParkingActive: true,
            currentFee: 2500,
            parkingStartTime: Date().addingTimeInterval(-3600),
            parkingLotName: "강남 지하주차장",
            discountInfo: "경차 20% 할인"
        )
    )
}
