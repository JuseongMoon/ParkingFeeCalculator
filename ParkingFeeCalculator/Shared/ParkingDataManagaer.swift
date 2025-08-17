//
//  ParkingDataManagaer.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import Foundation
import WidgetKit

class ParkingDataManager {
    static let shared = ParkingDataManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.parkingfeecalculator.widget")
    private let parkingDataKey = "sharedParkingData"
    
    private init() {}
    
    // 주차 데이터 저장 (메인 앱용)
    func saveParkingData(_ data: [String: Any]) {
        if let encoded = try? JSONSerialization.data(withJSONObject: data) {
            userDefaults?.set(encoded, forKey: parkingDataKey)
            // 위젯 새로고침 요청
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // 주차 데이터 불러오기 (메인 앱용 - JSON 직접 처리)
    func loadParkingData() -> [String: Any]? {
        guard let data = userDefaults?.data(forKey: parkingDataKey),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
    
    // 주차 상태 업데이트 (메인 앱용)
    func updateParkingStatus(isActive: Bool, fee: Int, startTime: Date, lotName: String) {
        let parkingData: [String: Any] = [
            "isParkingActive": isActive,
            "currentFee": fee,
            "parkingStartTime": startTime.timeIntervalSince1970,
            "parkingLotName": lotName
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: parkingData) {
            userDefaults?.set(data, forKey: parkingDataKey)
            // 위젯 새로고침 요청
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}


