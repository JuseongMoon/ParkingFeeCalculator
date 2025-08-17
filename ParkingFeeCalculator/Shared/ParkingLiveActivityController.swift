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
    private var activity: Activity<ParkingLiveActivityAttributes>?
    
    func start(startedAt: Date, lotName: String, initialFee: Int, 
               additionalFee: Int, additionalMinutes: Int, currentFee: Int) {
        print("Live Activity 시작 시도...")
        print("ActivityAuthorizationInfo().areActivitiesEnabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { 
            print("Live Activities가 비활성화되어 있습니다.")
            return 
        }
        
        let attributes = ParkingLiveActivityAttributes(
            initialFee: initialFee,
            additionalFee: additionalFee,
            additionalMinutes: additionalMinutes
        )
        let content = ParkingLiveActivityAttributes.ContentState(
            currentFee: currentFee,
            startedAt: startedAt,
            parkingLotName: lotName
        )
        
        do {
            activity = try Activity<ParkingLiveActivityAttributes>.request(
                attributes: attributes,
                contentState: content,
                pushType: nil
            )
            print("Live Activity 시작 성공!")
        } catch {
            print("Live Activity 시작 실패:", error)
        }
    }
    
    func update(currentFee: Int, startedAt: Date, lotName: String) {
        guard let activity else { return }
        let content = ParkingLiveActivityAttributes.ContentState(
            currentFee: currentFee,
            startedAt: startedAt,
            parkingLotName: lotName
        )
        Task { await activity.update(using: content) }
    }
    
    func end() {
        guard let activity else { return }
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
