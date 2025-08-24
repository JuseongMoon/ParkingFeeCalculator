//
//  ParkingFeeWidgetTimelineView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import WidgetKit
import SwiftUI
import Foundation
import ParkingFeeCore

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
    
    init() {
        // Darwin Notification 수신 설정 (위젯이 포어그라운드에 있을 때)
        DataChangeNotifier.shared.observeAllChanges {
            print("📡 [위젯] 주차 데이터 변경 알림 수신")
            WidgetCenter.shared.reloadAllTimelines()
        }
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
            data: loadParkingDataFromCore()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ParkingFeeWidgetTimelineEntry>) -> Void) {
        let currentData = loadParkingDataFromCore()
        
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
    
    // ParkingFeeCore를 사용한 데이터 로딩
    private func loadParkingDataFromCore() -> SharedParkingData {
        // ParkingSessionManager에서 현재 세션 확인
        guard let session = ParkingSessionManager.shared.currentSession() else {
            print("ℹ️ [위젯] 활성 주차 세션이 없습니다.")
            return SharedParkingData()
        }
        
        // 현재 주차비 계산
        let currentFee = session.currentFee
        
        print("✅ [위젯] ParkingFeeCore에서 데이터 로드 완료. 활성: true, 요금: \(currentFee)원")
        
        return SharedParkingData(
            isParkingActive: true,
            currentFee: currentFee,
            parkingStartTime: session.startTime,
            parkingLotName: session.parkingLot.name
        )
    }
    
    // 레거시 호환을 위한 기존 메서드 (사용되지 않음)
    private func loadParkingData() -> SharedParkingData {
        // 이제 ParkingFeeCore를 사용하므로 레거시 메서드는 새 메서드로 리다이렉트
        return loadParkingDataFromCore()
    }
}

