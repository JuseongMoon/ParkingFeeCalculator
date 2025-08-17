//
//  ParkingLiveActivityController.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import ActivityKit
import Foundation
import SwiftUI

// 임시로 주석 처리
/*
final class ParkingLiveActivityController: ObservableObject {
    private var activity: Activity<ParkingLiveActivityAttributes>?
    
    func start(startedAt: Date, lotName: String, initialFee: Int, 
               additionalFee: Int, additionalMinutes: Int, currentFee: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
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
*/
