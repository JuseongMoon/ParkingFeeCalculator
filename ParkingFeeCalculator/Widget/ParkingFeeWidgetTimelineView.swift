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
    private let userDefaults = UserDefaults(suiteName: "group.com.ScienceFiction.ParkingFeeCalculator")
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
        
        // 주차 상태에 따른 업데이트 빈도 조절
        let updateInterval: Int = currentData.isParkingActive ? 1 : 5 // 주차 중: 1분, 대기 중: 5분
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: updateInterval, to: Date()) ?? Date()
        let timeline = Timeline<ParkingFeeWidgetTimelineEntry>(entries: [entry], policy: .after(nextUpdateDate))
        
        print("🔄 [위젯] Timeline 업데이트 주기: \(updateInterval)분 (주차 활성: \(currentData.isParkingActive))")
        completion(timeline)
    }
    
    // 주차 데이터 불러오기
    private func loadParkingData() -> SharedParkingData {
        guard let userDefaults = userDefaults else {
            print("⚠️ [위젯] App Group UserDefaults를 사용할 수 없습니다.")
            return SharedParkingData()
        }
        
        guard let data = userDefaults.data(forKey: parkingDataKey) else {
            print("ℹ️ [위젯] 저장된 주차 데이터가 없습니다.")
            return SharedParkingData()
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let isParkingActive = json["isParkingActive"] as? Bool,
              let currentFee = json["currentFee"] as? Int,
              let parkingStartTimeInterval = json["parkingStartTime"] as? TimeInterval,
              let parkingLotName = json["parkingLotName"] as? String else {
            print("⚠️ [위젯] 주차 데이터를 파싱할 수 없습니다.")
            return SharedParkingData()
        }
        
        let parkingStartTime = Date(timeIntervalSince1970: parkingStartTimeInterval)
        print("✅ [위젯] 주차 데이터를 App Group에서 불러옴. 활성: \(isParkingActive), 요금: \(currentFee)원")
        
        return SharedParkingData(
            isParkingActive: isParkingActive,
            currentFee: currentFee,
            parkingStartTime: parkingStartTime,
            parkingLotName: parkingLotName
        )
    }
}

