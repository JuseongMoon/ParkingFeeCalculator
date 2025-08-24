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
    
    private let userDefaults = UserDefaults(suiteName: "group.com.ScienceFiction.ParkingFeeCalculator")
    private let parkingDataKey = "sharedParkingData"
    
    private init() {}
    
    // 주차 데이터 저장 (메인 앱용)
    func saveParkingData(_ data: [String: Any]) {
        guard let userDefaults = userDefaults else {
            print("⚠️ App Group UserDefaults를 사용할 수 없습니다.")
            return
        }
        
        guard let encoded = try? JSONSerialization.data(withJSONObject: data) else {
            print("⚠️ 주차 데이터를 JSON으로 변환할 수 없습니다.")
            return
        }
        
        userDefaults.set(encoded, forKey: parkingDataKey)
        print("✅ 주차 데이터가 App Group에 저장되었습니다.")
        
        // 위젯 새로고침 요청
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // 주차 데이터 불러오기 (메인 앱용 - JSON 직접 처리)
    func loadParkingData() -> [String: Any]? {
        guard let userDefaults = userDefaults else {
            print("⚠️ App Group UserDefaults를 사용할 수 없습니다.")
            return nil
        }
        
        guard let data = userDefaults.data(forKey: parkingDataKey) else {
            print("ℹ️ 저장된 주차 데이터가 없습니다.")
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("⚠️ 주차 데이터를 JSON으로 파싱할 수 없습니다.")
            return nil
        }
        
        print("✅ 주차 데이터를 App Group에서 불러왔습니다.")
        return json
    }
    
    // 주차 상태 업데이트 (메인 앱용)
    func updateParkingStatus(isActive: Bool, fee: Int, startTime: Date, lotName: String, additionalFreeMinutes: Int = 0) {
        guard let userDefaults = userDefaults else {
            print("⚠️ App Group UserDefaults를 사용할 수 없습니다.")
            return
        }
        
        let parkingData: [String: Any] = [
            "isParkingActive": isActive,
            "currentFee": fee,
            "parkingStartTime": startTime.timeIntervalSince1970,
            "parkingLotName": lotName,
            "additionalFreeMinutes": additionalFreeMinutes
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: parkingData) else {
            print("⚠️ 주차 상태 데이터를 JSON으로 변환할 수 없습니다.")
            return
        }
        
        userDefaults.set(data, forKey: parkingDataKey)
        print("✅ 주차 상태가 App Group에 업데이트되었습니다. 활성: \(isActive), 요금: \(fee)원")
        
        // 위젯 새로고침 요청
        WidgetCenter.shared.reloadAllTimelines()
    }
}


