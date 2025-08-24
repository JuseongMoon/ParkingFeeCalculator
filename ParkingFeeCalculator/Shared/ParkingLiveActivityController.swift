//
//  ParkingLiveActivityController.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import ActivityKit
import Foundation
import SwiftUI
import ParkingFeeCore

final class ParkingLiveActivityController: ObservableObject {
    private var activity: Activity<ParkingAttributes>?
    private var updateTimer: Timer?
    private var session: SharedParkingSession?
    
    func start(startedAt: Date, lotName: String, initialFee: Int, 
               additionalFee: Int, additionalMinutes: Int, currentFee: Int, 
               additionalFreeMinutes: Int = 0, discountInfo: String? = nil) {
        print("🚀 === Live Activity 시작 (ParkingFeeCore 사용) ===")
        print("ActivityAuthorizationInfo().areActivitiesEnabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { 
            print("❌ Live Activities가 비활성화되어 있습니다.")
            return 
        }
        
        // 현재 세션 정보 가져오기
        guard let currentSession = ParkingSessionManager.shared.currentSession() else {
            print("❌ 활성 세션이 없어서 Live Activity를 시작할 수 없습니다.")
            return
        }
        
        self.session = currentSession
        
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
            
            // 자체 타이머 시작 (1분마다 업데이트)
            startSelfUpdatingTimer()
            
            // Darwin Notification 수신 설정
            DataChangeNotifier.shared.observeAllChanges { [weak self] in
                self?.updateFromSession()
            }
            
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
        // 타이머 정리
        stopSelfUpdatingTimer()
        
        // Activity 종료
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
        self.session = nil
        
        print("🛑 Live Activity 종료 완료")
    }
    
    // MARK: - 자체 타이머 관리
    
    private func startSelfUpdatingTimer() {
        stopSelfUpdatingTimer() // 기존 타이머 정리
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            print("⏰ [Live Activity] 자체 타이머 업데이트")
            self?.updateFromSession()
        }
        
        print("⏰ [Live Activity] 자체 타이머 시작 (1분 간격)")
    }
    
    private func stopSelfUpdatingTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
        print("⏰ [Live Activity] 자체 타이머 정지")
    }
    
    // MARK: - 세션 기반 업데이트
    
    private func updateFromSession() {
        guard let currentSession = ParkingSessionManager.shared.currentSession(),
              let activity = activity else {
            print("❌ [Live Activity] 세션 또는 Activity가 없습니다.")
            return
        }
        
        // FeeCalculationService로 최신 주차비 계산
        let currentFee = currentSession.currentFee
        let elapsedTime = currentSession.elapsedTime
        let discountInfo = currentSession.discountInfo
        
        let content = ParkingAttributes.ContentState(
            currentFee: currentFee,
            elapsedTime: elapsedTime,
            startTime: currentSession.startTime,
            discountInfo: discountInfo
        )
        
        Task {
            await activity.update(.init(state: content, staleDate: nil))
            print("📱 [Live Activity] 업데이트 완료: \(currentFee)원, \(elapsedTime.koreanTimeFormat)")
        }
    }
}
