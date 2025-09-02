//
//  ParkingLiveActivityController.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//  Refactored by Claude Code on 9/2/25 - Push 기반으로 변경
//

import ActivityKit
import Foundation
import SwiftUI
import ParkingFeeCore
import ParkingShared

/// Push 기반 Live Activity 컨트롤러 (레거시 호환성 유지)
/// 내부적으로 RemoteLiveActivityService를 사용하여 AWS Lambda + APNs 통합
final class ParkingLiveActivityController: ObservableObject {
    private let remoteLiveActivityService = RemoteLiveActivityService.shared
    private let foregroundSyncService = ForegroundSyncService.shared
    
    /// Live Activity를 시작합니다 (Push 기반)
    /// - Parameters:
    ///   - startedAt: 주차 시작 시간
    ///   - lotName: 주차장 이름  
    ///   - currentFee: 현재 요금 (사용되지 않음 - 서버에서 계산)
    ///   - discountInfo: 할인 정보 (사용되지 않음 - 서버에서 계산)
    func start(startedAt: Date, lotName: String, currentFee: Int = 0, discountInfo: String? = nil) {
        print("🚀 === Live Activity 시작 (Push 기반으로 업그레이드) ===")
        print("ActivityAuthorizationInfo().areActivitiesEnabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { 
            print("❌ Live Activities가 비활성화되어 있습니다.")
            return 
        }
        
        // RemoteLiveActivityService로 위임 (Push 기반)
        remoteLiveActivityService.start(
            startedAt: startedAt,
            lotName: lotName,
            currentFee: currentFee,
            discountInfo: discountInfo
        )
        
        print("✅ Push 기반 Live Activity 시작 완료")
    }
    
    /// 수동 업데이트 (설정 변경 시 사용, 레거시 지원)
    /// 이제 포그라운드 보정 서비스를 통해 즉시 업데이트 수행
    func update(currentFee: Int = 0, startedAt: Date = Date(), discountInfo: String? = nil) {
        print("🔄 [ParkingLiveActivity] 수동 업데이트 요청 - 포그라운드 보정 사용")
        
        // 포그라운드 보정 서비스로 즉시 업데이트
        Task { @MainActor in
            await foregroundSyncService.performImmediateSync()
        }
    }
    
    /// Live Activity를 종료합니다
    func end() {
        print("🛑 [ParkingLiveActivity] Live Activity 종료 요청")
        
        // RemoteLiveActivityService로 위임
        remoteLiveActivityService.end()
        
        print("✅ [ParkingLiveActivity] Push 기반 Live Activity 종료 완료")
    }
    
    // MARK: - 레거시 호환성 속성들
    
    /// 현재 예약된 다음 업데이트 시간 (서버 기반으로 변경됨)
    var nextUpdateTime: Date? {
        // 서버 응답에서 다음 변경 시점 가져오기
        return AppGroupSnapshot.shared.serverResponse()?.nextChangeTime
    }
    
    /// 현재 스케줄러 상태 정보 (Push 기반 정보로 변경)
    var schedulerInfo: String {
        let serverResponse = AppGroupSnapshot.shared.serverResponse()
        let nextChange = serverResponse?.nextChangeTime?.description ?? "서버에서 관리"
        let scheduleId = serverResponse?.nextScheduleId ?? "없음"
        
        return """
        Push 기반 스케줄링 활성
        다음 서버 업데이트: \(nextChange)
        스케줄 ID: \(scheduleId)
        """
    }
    
    /// 현재 활성 상태 확인
    var isActive: Bool {
        return remoteLiveActivityService.isActive
    }
    
    /// 디버깅용 상태 정보
    var debugInfo: String {
        return """
        === Push 기반 Live Activity ===
        \(remoteLiveActivityService.currentActivityInfo)
        
        === 포그라운드 보정 상태 ===
        \(foregroundSyncService.debugInfo)
        ===============================
        """
    }

// MARK: - App Lifecycle 처리 (Push 기반으로 단순화)
extension ParkingLiveActivityController {
    
    /// 앱이 백그라운드로 전환될 때 호출
    /// Push 기반에서는 서버가 관리하므로 특별한 처리 불필요
    func handleAppDidEnterBackground() {
        print("📱 [ParkingLiveActivity] 앱 백그라운드 전환 - Push 기반이므로 서버가 관리")
        // 백그라운드에서도 Push 알림이 도착하므로 추가 작업 불필요
    }
    
    /// 앱이 포그라운드로 복귀할 때 호출
    /// 포그라운드 보정 서비스가 자동으로 동기화 수행
    func handleAppDidBecomeActive() {
        print("📱 [ParkingLiveActivity] 앱 포그라운드 복귀 - 자동 보정 수행")
        // ForegroundSyncService가 자동으로 NotificationCenter를 통해 보정 실행
    }
}
