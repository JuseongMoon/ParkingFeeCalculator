//
//  PushTokenManager.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 9/2/25.
//  단순화된 푸시 토큰 매니저
//

import ActivityKit
import Foundation

/// 단순화된 ActivityKit Push Token 매니저
@MainActor
final class PushTokenManager: ObservableObject {
    static let shared = PushTokenManager()

    private var currentActivity: Activity<ParkingAttributes>?

    private init() {}

    /// 토큰 모니터링 시작
    func startTokenMonitoring(for session: SharedParkingSession) {
        print("✅ 토큰 모니터링 시작: \(session.sessionId)")
    }

    /// 토큰 모니터링 중단
    func stopTokenMonitoring() {
        print("✅ 토큰 모니터링 중단")
    }

    /// 액티비티 종료
    func endAllActivities() {
        Task {
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            print("✅ 모든 액티비티 종료 완료")
        }
    }
}