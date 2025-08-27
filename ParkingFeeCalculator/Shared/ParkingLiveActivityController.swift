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
import ParkingShared

final class ParkingLiveActivityController: ObservableObject {
    private var activity: Activity<ParkingAttributes>?
    private var session: SharedParkingSession?
    private let feeUpdateScheduler = FeeUpdateScheduler()
    
    func start(startedAt: Date, lotName: String, currentFee: Int = 0, discountInfo: String? = nil) {
        print("🚀 === Live Activity 시작 (경계 기반 업데이트) ===")
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
        
        // ParkingFeeCore로 현재 요금 계산
        let now = Date()
        let feeResult = FeeCalculationService.shared.calculateFee(for: currentSession, at: now)
        
        // 다음 변경 시점 계산
        let nextChange = FeeScheduler.nextChangeDate(
            startTime: currentSession.startTime,
            currentTime: now,
            calculator: currentSession.parkingLot.parkingFeeCalculator,
            additionalFreeMinutes: currentSession.additionalFreeMinutes
        )
        
        let attributes = ParkingAttributes(parkingLotName: lotName)
        let content = ParkingAttributes.ContentState(
            startTime: startedAt,
            parkingLotName: lotName,
            currentFee: feeResult.finalFee,
            discountInfo: feeResult.appliedDiscount?.name,
            nextChangeDate: nextChange
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
            print("📅 다음 변경 시점: \(nextChange?.description ?? "없음")")
            
            // 경계 기반 타이머 시작
            if let activity = activity {
                feeUpdateScheduler.schedule(
                    for: activity,
                    session: currentSession,
                    nextChangeDate: nextChange
                )
            }
            
            // 설정 변경 시 즉시 업데이트
            DataChangeNotifier.shared.observeAllChanges { [weak self] in
                self?.handleSettingsChanged()
            }
            
        } catch {
            print("❌ Live Activity 시작 실패: \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }
    
    /// 수동 업데이트 (설정 변경 시 사용, 레거시 지원)
    func update(currentFee: Int = 0, startedAt: Date = Date(), discountInfo: String? = nil) {
        guard let currentSession = ParkingSessionManager.shared.currentSession() else { return }
        
        Task { @MainActor in
            await feeUpdateScheduler.immediateUpdate(with: currentSession)
        }
    }
    
    func end() {
        // 타이머 중단
        feeUpdateScheduler.stop()
        
        // Activity 종료
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
        self.session = nil
        
        print("🛑 Live Activity 종료 완료")
    }
    
    // MARK: - 세션 기반 업데이트 (설정 변경 시에만)
    
    private func handleSettingsChanged() {
        guard let currentSession = ParkingSessionManager.shared.currentSession() else {
            print("❌ [Live Activity] 세션이 없어 설정 변경 처리 불가")
            return
        }
        
        // 세션 업데이트
        self.session = currentSession
        
        // 즉시 업데이트 및 타이머 재예약
        Task { @MainActor in
            await feeUpdateScheduler.immediateUpdate(with: currentSession)
            print("📱 [Live Activity] 설정 변경으로 인한 업데이트 완료")
        }
    }
    
    /// 현재 예약된 다음 업데이트 시간
    var nextUpdateTime: Date? {
        guard let session = session else { return nil }
        return FeeScheduler.nextChangeDate(
            startTime: session.startTime,
            currentTime: Date(),
            calculator: session.parkingLot.parkingFeeCalculator,
            additionalFreeMinutes: session.additionalFreeMinutes
        )
    }
    
    /// 현재 스케줄러 상태 정보
    var schedulerInfo: String {
        return feeUpdateScheduler.scheduleInfo
    }
}

// MARK: - App Lifecycle 처리
extension ParkingLiveActivityController {
    
    /// 앱이 백그라운드로 전환될 때 호출
    func handleAppDidEnterBackground() {
        feeUpdateScheduler.handleAppDidEnterBackground()
    }
    
    /// 앱이 포그라운드로 복귀할 때 호출
    func handleAppDidBecomeActive() {
        feeUpdateScheduler.handleAppDidBecomeActive()
    }
}
