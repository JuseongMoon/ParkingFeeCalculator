//
//  ParkingLiveActivityController.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import ActivityKit
import Foundation
import SwiftUI

final class ParkingLiveActivityController: ObservableObject {
    private var activity: Activity<ParkingAttributes>?
    
    func start(startedAt: Date, lotName: String, initialFee: Int, 
               additionalFee: Int, additionalMinutes: Int, currentFee: Int, 
               additionalFreeMinutes: Int = 0, discountInfo: String? = nil) {
        print("=== Live Activity 시작 시도 ===")
        print("ActivityAuthorizationInfo().areActivitiesEnabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
        print("ActivityAuthorizationInfo().frequentPushesEnabled: \(ActivityAuthorizationInfo().frequentPushesEnabled)")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { 
            print("❌ Live Activities가 비활성화되어 있습니다.")
            return 
        }
        
        let attributes = ParkingAttributes(parkingLotName: lotName)
        let content = ParkingAttributes.ContentState(
            currentFee: currentFee,
            elapsedTime: Date().timeIntervalSince(startedAt),
            startTime: startedAt,
            discountInfo: discountInfo
        )
        
        do {
            print("✅ Live Activity 요청 시도...")
            print("Attributes: \(attributes)")
            print("Content: \(content)")
            
            activity = try Activity<ParkingAttributes>.request(
                attributes: attributes,
                content: .init(state: content, staleDate: nil),
                pushType: nil
            )
            print("✅ Live Activity 시작 성공!")
            print("Activity ID: \(activity?.id ?? "Unknown")")
        } catch {
            print("❌ Live Activity 시작 실패: \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }
    
    func update(currentFee: Int, startedAt: Date, additionalFreeMinutes: Int = 0, discountInfo: String? = nil) {
        guard let activity else { return }
        let content = ParkingAttributes.ContentState(
            currentFee: currentFee,
            elapsedTime: Date().timeIntervalSince(startedAt),
            startTime: startedAt,
            discountInfo: discountInfo
        )
        Task { await activity.update(.init(state: content, staleDate: nil)) }
    }
    
    func end() {
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
