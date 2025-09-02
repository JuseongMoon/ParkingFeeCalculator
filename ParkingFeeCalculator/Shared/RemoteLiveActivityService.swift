//
//  RemoteLiveActivityService.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 9/2/25.
//

import ActivityKit
import Foundation
import SwiftUI
import ParkingFeeCore
import ParkingShared

/// Push 기반 Live Activity를 관리하는 서비스 (EventBridge + Lambda + APNs)
@MainActor
final class RemoteLiveActivityService: ObservableObject {
    static let shared = RemoteLiveActivityService()
    
    private var activity: Activity<ParkingAttributes>?
    private var session: SharedParkingSession?
    
    private init() {}
    
    /// Push 기반 Live Activity를 시작합니다
    /// - Parameters:
    ///   - startedAt: 주차 시작 시간
    ///   - lotName: 주차장 이름
    ///   - currentFee: 현재 요금 (초기값)
    ///   - discountInfo: 할인 정보
    func start(startedAt: Date, lotName: String, currentFee: Int = 0, discountInfo: String? = nil) {
        print("🚀 === Remote Live Activity 시작 (Push 기반) ===")
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
        
        // 로컬에서 현재 요금 계산 (초기값)
        let now = Date()
        let feeResult = FeeCalculationService.shared.calculateFee(for: currentSession, at: now)
        
        // ParkingAttributes 생성 (4KB 제한 고려하여 최소 필드만)
        let attributes = ParkingAttributes(parkingLotName: lotName)
        let content = ParkingAttributes.ContentState(
            startTime: startedAt,
            parkingLotName: lotName,
            currentFee: feeResult.finalFee,
            discountInfo: feeResult.appliedDiscount?.name,
            nextChangeDate: nil // 서버에서 계산하여 Push로 업데이트
        )
        
        do {
            print("✅ Live Activity 요청 시도 (Push Token 기반)...")
            print("Attributes: \(attributes)")
            print("Content: \(content)")
            
            // 핵심: pushType을 .token으로 설정하여 Push 업데이트 활성화
            activity = try Activity<ParkingAttributes>.request(
                attributes: attributes,
                content: .init(state: content, staleDate: nil),
                pushType: .token // 중요: Push 기반 업데이트를 위해 .token 설정
            )
            
            print("✅ Live Activity 시작 성공!")
            print("Activity ID: \(activity?.id ?? "Unknown")")
            
            // Push Token 모니터링 시작
            if let activity = activity {
                PushTokenManager.shared.startTokenMonitoring(for: activity)
                
                // 서버로 세션 시작 요청 보내기
                Task {
                    await sendSessionStartRequest(with: currentSession)
                }
            }
            
        } catch {
            print("❌ Live Activity 시작 실패: \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }
    
    /// 서버로 세션 시작 요청을 보냅니다
    /// - Parameter session: 시작할 세션 정보
    private func sendSessionStartRequest(with session: SharedParkingSession) async {
        do {
            let request = ParkingSessionRequest(session: session)
            let response = try await NetworkService.shared.startParkingSession(request)
            
            print("✅ [RemoteLiveActivity] 서버 세션 시작 완료")
            print("Next Schedule ID: \(response.nextScheduleId ?? "없음")")
            print("Next Change Time: \(response.nextChangeTime?.description ?? "없음")")
            
            // App Group에 서버 응답 저장
            AppGroupSnapshot.shared.updateServerResponse(response)
            
        } catch {
            print("❌ [RemoteLiveActivity] 서버 세션 시작 실패: \(error)")
            
            // 실패 시 재시도 (5초 후)
            Task {
                try? await Task.sleep(for: .seconds(5))
                await sendSessionStartRequest(with: session)
            }
        }
    }
    
    /// Live Activity를 종료합니다
    func end() {
        print("🛑 Remote Live Activity 종료 시작")
        
        // Push Token 모니터링 중단
        PushTokenManager.shared.stopTokenMonitoring()
        
        // 서버로 세션 종료 요청
        if let session = session {
            Task {
                do {
                    try await NetworkService.shared.endParkingSession(session.sessionId)
                    print("✅ [RemoteLiveActivity] 서버 세션 종료 완료")
                } catch {
                    print("❌ [RemoteLiveActivity] 서버 세션 종료 실패: \(error)")
                }
            }
        }
        
        // Activity 종료
        guard let activity else { 
            print("⚠️ [RemoteLiveActivity] Activity가 이미 종료됨")
            return 
        }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            print("✅ [RemoteLiveActivity] Live Activity 종료 완료")
        }
        
        self.activity = nil
        self.session = nil
        
        // App Group 스냅샷 정리
        AppGroupSnapshot.shared.clearSession()
    }
    
    /// 현재 Activity의 상태 정보를 반환합니다
    var currentActivityInfo: String {
        guard let activity = activity,
              let session = session else {
            return "Live Activity 비활성"
        }
        
        return """
        Activity ID: \(activity.id)
        세션 ID: \(session.sessionId)
        주차장: \(session.parkingLot.name)
        Push Token 모니터링: \(PushTokenManager.shared.isMonitoring ? "활성" : "비활성")
        """
    }
    
    /// 현재 Activity가 활성 상태인지 확인합니다
    var isActive: Bool {
        return activity != nil
    }
}

// MARK: - iOS 18+ Push-to-Start 지원 (향후 확장)
@available(iOS 18.0, *)
extension RemoteLiveActivityService {
    
    /// iOS 18+에서 Push-to-Start 기능을 위한 채널 등록
    /// - Parameter channelId: 고유한 채널 ID
    func registerPushToStartChannel(_ channelId: String) async {
        // iOS 18+ Push-to-Start 구현
        // 현재는 플레이스홀더로 두고 필요 시 구현
        print("📱 [RemoteLiveActivity] iOS 18+ Push-to-Start 채널 등록: \(channelId)")
    }
}

// MARK: - 디버깅 및 모니터링
extension RemoteLiveActivityService {
    
    /// 디버깅용 상태 덤프
    func debugDump() {
        print("""
        === Remote Live Activity Status ===
        Active: \(isActive)
        \(currentActivityInfo)
        
        === Push Token Manager ===
        \(PushTokenManager.shared.debugInfo)
        
        === App Group Snapshot ===
        \(AppGroupSnapshot.shared.debugInfo)
        ===================================
        """)
    }
}