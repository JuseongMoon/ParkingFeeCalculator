//
//  RemoteLiveActivityService.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 9/2/25.
//  단순화된 Live Activity 서비스
//

import ActivityKit
import Foundation
import SwiftUI

/// 단순화된 Live Activity 서비스
@MainActor
final class RemoteLiveActivityService: ObservableObject {
    static let shared = RemoteLiveActivityService()

    @Published var isActive = false
    private var currentActivity: Activity<ParkingAttributes>?

    private init() {}

    /// Live Activity 시작
    func start(startedAt: Date, lotName: String, currentFee: Int = 0, discountInfo: String? = nil) {
        print("🚀 Live Activity 시작")

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities가 비활성화되어 있습니다.")
            return
        }

        let attributes = ParkingAttributes(parkingLotName: lotName)
        let content = ParkingAttributes.ContentState(
            startTime: startedAt,
            parkingLotName: lotName,
            currentFee: currentFee,
            discountInfo: discountInfo
        )

        do {
            let activity = try Activity<ParkingAttributes>.request(
                attributes: attributes,
                content: .init(state: content, staleDate: nil)
            )

            currentActivity = activity
            isActive = true
            print("✅ Live Activity 시작 성공: \(activity.id)")
        } catch {
            print("❌ Live Activity 시작 실패: \(error)")
        }
    }

    /// Live Activity 종료
    func end() {
        print("🛑 Live Activity 종료")

        Task {
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            isActive = false
            print("✅ Live Activity 종료 완료")
        }
    }

    /// 현재 활동 정보
    var currentActivityInfo: String {
        return isActive ? "활성 상태" : "비활성 상태"
    }
}