//
//  ParkingFeeWidgetTimelineView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import WidgetKit
import SwiftUI
import Foundation

// SharedParkingData는 다른 파일에서 정의됨

struct ParkingFeeWidgetTimelineEntry: TimelineEntry {
    let date: Date
    let data: SharedParkingData
}

struct ParkingFeeWidgetTimelineProvider: TimelineProvider {
    private let userDefaults = UserDefaults(suiteName: "group.com.ScienceFiction.ParkingFeeCalculator")
    private let parkingDataKey = "sharedParkingData"
    
    init() {
        // Widget Extension에서는 Darwin Notification 대신 UserDefaults 기반 타임라인 업데이트 사용
    }
    
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
    
    // UserDefaults 기반 데이터 로딩
    private func loadParkingData() -> SharedParkingData {
        guard let data = userDefaults?.data(forKey: parkingDataKey),
              let sharedData = try? JSONDecoder().decode(SharedParkingData.self, from: data) else {
            print("ℹ️ [위젯] 저장된 주차 데이터가 없습니다.")
            return SharedParkingData()
        }

        print("✅ [위젯] UserDefaults에서 데이터 로드 완료. 활성: \(sharedData.isParkingActive), 요금: \(sharedData.currentFee)원")
        return sharedData
    }
}

