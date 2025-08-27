//
//  FeeUpdateScheduler.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 8/27/25.
//

import ActivityKit
import Foundation
import SwiftUI
import ParkingFeeCore
import ParkingShared

/// Live Activity의 요금 업데이트를 경계 시점에만 스케줄링하는 타이머 관리 클래스
final class FeeUpdateScheduler: ObservableObject {
    private var timer: Timer?
    private var currentActivity: Activity<ParkingAttributes>?
    private var currentSession: SharedParkingSession?
    
    /// 다음 경계 시점에 타이머를 예약합니다
    /// - Parameters:
    ///   - activity: 업데이트할 Live Activity
    ///   - session: 현재 주차 세션
    ///   - nextChangeDate: 다음 요금 변경 시점
    func schedule(
        for activity: Activity<ParkingAttributes>,
        session: SharedParkingSession,
        nextChangeDate: Date?
    ) {
        // 기존 타이머 무효화
        timer?.invalidate()
        timer = nil
        
        // 현재 정보 저장
        self.currentActivity = activity
        self.currentSession = session
        
        guard let nextChange = nextChangeDate else {
            print("📱 [FeeScheduler] 더 이상 요금 변경이 없어 타이머 예약 중단")
            return
        }
        
        let now = Date()
        let interval = max(0, nextChange.timeIntervalSince(now))
        
        print("📱 [FeeScheduler] 다음 업데이트 예약: \(nextChange) (약 \(Int(interval))초 후)")
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.tick()
            }
        }
    }
    
    /// 경계 시점에 도달했을 때 실행되는 메서드
    /// 요금을 재계산하고 Live Activity를 업데이트한 후 다음 타이머를 예약합니다
    @MainActor
    private func tick() async {
        guard let activity = currentActivity,
              let session = currentSession else {
            print("❌ [FeeScheduler] Activity 또는 Session이 없습니다")
            return
        }
        
        let now = Date()
        print("📱 [FeeScheduler] 경계 시점 도달 - 요금 재계산 시작: \(now)")
        
        // ParkingFeeCore로 최신 요금 계산
        let result = FeeCalculationService.shared.calculateFee(for: session, at: now)
        
        // 다음 변경 시점 계산
        let nextChange = FeeScheduler.nextChangeDate(
            startTime: session.startTime,
            currentTime: now,
            calculator: session.parkingLot.parkingFeeCalculator,
            additionalFreeMinutes: session.additionalFreeMinutes
        )
        
        // ContentState 업데이트
        let updatedState = ParkingAttributes.ContentState(
            startTime: session.startTime,
            parkingLotName: session.parkingLot.name,
            currentFee: result.finalFee,
            discountInfo: result.appliedDiscount?.name,
            nextChangeDate: nextChange
        )
        
        // Live Activity 업데이트
        do {
            let content = ActivityContent(state: updatedState, staleDate: nil)
            await activity.update(content)
            print("✅ [FeeScheduler] Live Activity 업데이트 완료 - 요금: \(result.finalFee)원")
            
            // 다음 타이머 예약
            schedule(for: activity, session: session, nextChangeDate: nextChange)
            
        } catch {
            print("❌ [FeeScheduler] Live Activity 업데이트 실패: \(error)")
        }
    }
    
    /// 즉시 요금을 재계산하고 업데이트합니다 (설정 변경 시)
    /// - Parameter newSession: 업데이트된 세션 (할인 등 변경사항 반영)
    @MainActor
    func immediateUpdate(with newSession: SharedParkingSession) async {
        guard let activity = currentActivity else {
            print("❌ [FeeScheduler] Activity가 없어 즉시 업데이트 불가")
            return
        }
        
        // 세션 정보 업데이트
        self.currentSession = newSession
        
        let now = Date()
        let result = FeeCalculationService.shared.calculateFee(for: newSession, at: now)
        
        let nextChange = FeeScheduler.nextChangeDate(
            startTime: newSession.startTime,
            currentTime: now,
            calculator: newSession.parkingLot.parkingFeeCalculator,
            additionalFreeMinutes: newSession.additionalFreeMinutes
        )
        
        let updatedState = ParkingAttributes.ContentState(
            startTime: newSession.startTime,
            parkingLotName: newSession.parkingLot.name,
            currentFee: result.finalFee,
            discountInfo: result.appliedDiscount?.name,
            nextChangeDate: nextChange
        )
        
        do {
            let content = ActivityContent(state: updatedState, staleDate: nil)
            await activity.update(content)
            print("✅ [FeeScheduler] 즉시 업데이트 완료 - 요금: \(result.finalFee)원")
            
            // 기존 타이머 취소하고 새 타이머 예약
            schedule(for: activity, session: newSession, nextChangeDate: nextChange)
            
        } catch {
            print("❌ [FeeScheduler] 즉시 업데이트 실패: \(error)")
        }
    }
    
    /// 타이머를 중단하고 정리합니다
    func stop() {
        timer?.invalidate()
        timer = nil
        currentActivity = nil
        currentSession = nil
        print("🛑 [FeeScheduler] 타이머 중단 및 정리 완료")
    }
    
    /// 현재 다음 변경까지 남은 시간을 반환합니다 (디버깅용)
    var timeUntilNextUpdate: TimeInterval? {
        guard let session = currentSession else { return nil }
        
        return FeeScheduler.timeUntilNextChange(
            startTime: session.startTime,
            calculator: session.parkingLot.parkingFeeCalculator,
            additionalFreeMinutes: session.additionalFreeMinutes
        )
    }
    
    /// 현재 스케줄 정보를 반환합니다 (디버깅/모니터링용)
    var scheduleInfo: String {
        guard let session = currentSession else { return "세션 없음" }
        
        let schedule = FeeScheduler.generateSchedule(
            startTime: session.startTime,
            duration: 3600 * 4, // 4시간
            calculator: session.parkingLot.parkingFeeCalculator,
            additionalFreeMinutes: session.additionalFreeMinutes
        )
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        let scheduleStrings = schedule.prefix(5).map { formatter.string(from: $0) }
        return "다음 변경 시점들: \(scheduleStrings.joined(separator: ", "))"
    }
    
    deinit {
        stop()
    }
}

// MARK: - Background/Foreground 처리
extension FeeUpdateScheduler {
    
    /// 앱이 백그라운드로 전환될 때 호출
    func handleAppDidEnterBackground() {
        // 백그라운드에서도 타이머는 유지되지만 시스템 제약이 있음
        // APNs Push로 대체하는 것이 더 안정적
        print("📱 [FeeScheduler] 앱이 백그라운드로 전환됨")
    }
    
    /// 앱이 포그라운드로 복귀할 때 호출
    func handleAppDidBecomeActive() {
        guard let session = currentSession,
              let activity = currentActivity else {
            return
        }
        
        print("📱 [FeeScheduler] 앱이 포그라운드로 복귀 - 타이머 상태 확인")
        
        // 현재 시간 기준으로 다음 변경 시점 재계산
        let now = Date()
        let nextChange = FeeScheduler.nextChangeDate(
            startTime: session.startTime,
            currentTime: now,
            calculator: session.parkingLot.parkingFeeCalculator,
            additionalFreeMinutes: session.additionalFreeMinutes
        )
        
        // 타이머가 이미 지났거나 부정확할 수 있으므로 재예약
        schedule(for: activity, session: session, nextChangeDate: nextChange)
        
        // 현재 요금도 업데이트 (시간이 많이 지났을 수 있음)
        Task { @MainActor in
            await immediateUpdate(with: session)
        }
    }
}

// MARK: - 편의 메서드
extension FeeUpdateScheduler {
    
    /// 현재 활성화된 스케줄러인지 확인
    var isActive: Bool {
        return timer != nil && currentActivity != nil
    }
    
    /// 현재 세션의 주차장 이름
    var currentParkingLotName: String {
        return currentSession?.parkingLot.name ?? ""
    }
    
    /// 현재 세션의 경과 시간
    var currentElapsedTime: TimeInterval {
        guard let startTime = currentSession?.startTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
}