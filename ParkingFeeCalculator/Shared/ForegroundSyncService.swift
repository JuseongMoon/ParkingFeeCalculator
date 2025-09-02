//
//  ForegroundSyncService.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 9/2/25.
//

import ActivityKit
import Foundation
import SwiftUI
import WidgetKit
import ParkingFeeCore

/// 포그라운드 복귀 시 UX 안정성을 위한 즉시 보정 서비스
/// Push 지연/유실에 대비하여 사용자 액션 시 로컬 재계산으로 즉시 보정
@MainActor
final class ForegroundSyncService: ObservableObject {
    static let shared = ForegroundSyncService()
    
    @Published var isPerformingSync = false
    @Published var lastSyncTime: Date?
    
    private init() {
        // App Lifecycle 이벤트 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    /// 앱이 포그라운드로 복귀할 때 즉시 보정 실행
    @objc private func appDidBecomeActive() {
        print("📱 [ForegroundSync] 앱 포그라운드 복귀 - 보정 시작")
        
        Task {
            await performImmediateSync()
        }
    }
    
    /// 앱이 백그라운드로 전환될 때 처리
    @objc private func appDidEnterBackground() {
        print("📱 [ForegroundSync] 앱 백그라운드 전환")
        
        // 스냅샷을 5분 후 오래된 상태로 마킹하는 타이머 설정
        Task {
            try? await Task.sleep(for: .seconds(300)) // 5분
            AppGroupSnapshot.shared.markFeeSnapshotAsStale()
        }
    }
    
    /// 즉시 보정을 수행합니다 (UX 안정성을 위한 핵심 기능)
    func performImmediateSync() async {
        guard !isPerformingSync else {
            print("⚠️ [ForegroundSync] 이미 보정 진행 중")
            return
        }
        
        isPerformingSync = true
        defer { isPerformingSync = false }
        
        // 1. 현재 활성 세션 확인
        guard let currentSession = ParkingSessionManager.shared.currentSession() else {
            print("⚠️ [ForegroundSync] 활성 세션이 없어 보정 건너뜀")
            return
        }
        
        print("🔄 [ForegroundSync] 즉시 보정 시작 - 세션: \(currentSession.sessionId)")
        
        let now = Date()
        
        // 2. 로컬에서 최신 요금 즉시 계산
        let feeResult = FeeCalculationService.shared.calculateFee(for: currentSession, at: now)
        
        print("📊 [ForegroundSync] 로컬 계산 완료 - 요금: \(feeResult.finalFee)원")
        
        // 3. Live Activity 즉시 업데이트 (사용자가 즉시 최신 상태를 볼 수 있도록)
        await updateLiveActivityIfNeeded(
            session: currentSession,
            feeResult: feeResult,
            calculatedAt: now
        )
        
        // 4. App Group 스냅샷 갱신 (위젯 동기화)
        AppGroupSnapshot.shared.updateSessionSnapshot(currentSession)
        AppGroupSnapshot.shared.updateFeeSnapshot(
            feeResult.finalFee,
            discountInfo: feeResult.appliedDiscount?.name,
            calculatedAt: now
        )
        
        // 5. 위젯 강제 갱신 (즉시성 보장)
        WidgetCenter.shared.reloadAllTimelines()
        
        lastSyncTime = now
        
        print("✅ [ForegroundSync] 즉시 보정 완료")
        
        // 6. 선택적: 서버 상태와 동기화 (네트워크 에러 시에도 로컬 보정은 완료됨)
        await syncWithServerIfNeeded(currentSession)
    }
    
    /// 필요한 경우 Live Activity를 로컬에서 즉시 업데이트합니다
    /// - Parameters:
    ///   - session: 현재 세션
    ///   - feeResult: 계산된 요금 결과
    ///   - calculatedAt: 계산 시점
    private func updateLiveActivityIfNeeded(
        session: SharedParkingSession,
        feeResult: ParkingFeeResult,
        calculatedAt: Date
    ) async {
        // 현재 활성 Live Activity 찾기
        let activities = Activity<ParkingAttributes>.activities
        
        guard let currentActivity = activities.first(where: { activity in
            activity.attributes.parkingLotName == session.parkingLot.name
        }) else {
            print("⚠️ [ForegroundSync] 활성 Live Activity 없음")
            return
        }
        
        // ContentState 업데이트 (서버 푸시와 동일한 구조 유지)
        let updatedState = ParkingAttributes.ContentState(
            startTime: session.startTime,
            parkingLotName: session.parkingLot.name,
            currentFee: feeResult.finalFee,
            discountInfo: feeResult.appliedDiscount?.name,
            nextChangeDate: nil // 서버에서 다음 Push로 업데이트될 예정
        )
        
        do {
            let content = ActivityContent(state: updatedState, staleDate: nil)
            await currentActivity.update(content)
            
            print("✅ [ForegroundSync] Live Activity 즉시 업데이트 완료")
            
        } catch {
            print("❌ [ForegroundSync] Live Activity 업데이트 실패: \(error)")
        }
    }
    
    /// 필요한 경우 서버와 동기화합니다 (선택적, 실패해도 로컬 보정은 유지)
    /// - Parameter session: 현재 세션
    private func syncWithServerIfNeeded(_ session: SharedParkingSession) async {
        // 서버 응답이 5분 이상 오래된 경우에만 재동기화 시도
        let serverResponse = AppGroupSnapshot.shared.serverResponse()
        
        if let lastServerUpdate = serverResponse?.nextChangeTime,
           Date().timeIntervalSince(lastServerUpdate) < 300 {
            print("📡 [ForegroundSync] 서버 상태가 최신이므로 동기화 건너뜀")
            return
        }
        
        do {
            // 서버에 현재 상태 확인 요청 (가벼운 GET 요청)
            // TODO: 실제 API 엔드포인트 구현 필요
            print("📡 [ForegroundSync] 서버와 동기화 중...")
            
            // 실패해도 로컬 보정은 이미 완료된 상태이므로 UX에 영향 없음
            
        } catch {
            print("⚠️ [ForegroundSync] 서버 동기화 실패 (로컬 보정은 완료됨): \(error)")
        }
    }
    
    /// 수동으로 보정을 트리거합니다 (사용자 액션 시)
    func triggerManualSync() {
        print("👆 [ForegroundSync] 수동 보정 트리거")
        
        Task {
            await performImmediateSync()
        }
    }
    
    /// 마지막 보정으로부터 경과 시간을 반환합니다
    var timeSinceLastSync: TimeInterval? {
        guard let lastSyncTime = lastSyncTime else { return nil }
        return Date().timeIntervalSince(lastSyncTime)
    }
    
    /// 보정이 필요한지 확인합니다 (5분 이상 경과)
    var needsSync: Bool {
        guard let elapsed = timeSinceLastSync else { return true }
        return elapsed > 300 // 5분
    }
    
    /// 디버깅용 상태 정보
    var debugInfo: String {
        let lastSync = lastSyncTime?.description ?? "없음"
        let elapsed = timeSinceLastSync.map { "\(Int($0))초 전" } ?? "없음"
        
        return """
        마지막 보정: \(lastSync)
        경과 시간: \(elapsed)
        보정 필요: \(needsSync)
        진행 중: \(isPerformingSync)
        """
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - SwiftUI Integration

/// 포그라운드 보정 상태를 표시하는 View Modifier
struct ForegroundSyncIndicator: ViewModifier {
    @StateObject private var syncService = ForegroundSyncService.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if syncService.isPerformingSync {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("동기화 중...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: syncService.isPerformingSync)
    }
}

extension View {
    /// 포그라운드 동기화 인디케이터를 추가합니다
    func foregroundSyncIndicator() -> some View {
        self.modifier(ForegroundSyncIndicator())
    }
}