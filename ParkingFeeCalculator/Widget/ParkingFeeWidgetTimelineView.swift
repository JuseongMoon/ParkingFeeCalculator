//
//  ParkingFeeWidgetTimelineView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import WidgetKit
import SwiftUI
import Foundation

// 위젯 전용 공유 데이터 모델
struct SharedParkingData: Codable {
    let isParkingActive: Bool
    let currentFee: Int
    let parkingStartTime: Date
    let parkingLotName: String
    
    init(isParkingActive: Bool = false, currentFee: Int = 0, parkingStartTime: Date = Date(), parkingLotName: String = "") {
        self.isParkingActive = isParkingActive
        self.currentFee = currentFee
        self.parkingStartTime = parkingStartTime
        self.parkingLotName = parkingLotName
    }
}

struct ParkingFeeWidgetTimelineEntry: TimelineEntry {
    let date: Date
    let data: SharedParkingData
}

struct ParkingFeeWidgetTimelineProvider: TimelineProvider {
    private let userDefaults = UserDefaults(suiteName: "group.com.parkingfeecalculator.widget")
    private let parkingDataKey = "sharedParkingData"
    
    func placeholder(in context: Context) -> ParkingFeeWidgetTimelineEntry {
        ParkingFeeWidgetTimelineEntry(
            date: Date(),
            data: SharedParkingData()
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ParkingFeeWidgetTimelineEntry) -> Void) {
        let entry = ParkingFeeWidgetTimelineEntry(
            date: Date(),
            data: loadParkingData()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ParkingFeeWidgetTimelineEntry>) -> Void) {
        let currentData = loadParkingData()
        
        let entry = ParkingFeeWidgetTimelineEntry(
            date: Date(),
            data: currentData
        )
        
        // 항상 1분마다 업데이트 (주차 상태에 관계없이)
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
        let timeline = Timeline<ParkingFeeWidgetTimelineEntry>(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    // 주차 데이터 불러오기
    private func loadParkingData() -> SharedParkingData {
        guard let data = userDefaults?.data(forKey: parkingDataKey),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let isParkingActive = json["isParkingActive"] as? Bool,
              let currentFee = json["currentFee"] as? Int,
              let parkingStartTimeInterval = json["parkingStartTime"] as? TimeInterval,
              let parkingLotName = json["parkingLotName"] as? String else {
            return SharedParkingData()
        }
        
        let parkingStartTime = Date(timeIntervalSince1970: parkingStartTimeInterval)
        return SharedParkingData(
            isParkingActive: isParkingActive,
            currentFee: currentFee,
            parkingStartTime: parkingStartTime,
            parkingLotName: parkingLotName
        )
    }
}

