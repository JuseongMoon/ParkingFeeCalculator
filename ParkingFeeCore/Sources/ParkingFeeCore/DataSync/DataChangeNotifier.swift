//
//  DataChangeNotifier.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/24/25.
//  Simplified for Push-based architecture on 9/2/25.
//

import Foundation
import WidgetKit

/// 단순화된 데이터 변경 알림 클래스 (Push 기반 아키텍처용)  
/// Darwin Notification 대신 App Group 스냅샷 기반으로 단순화
public final class DataChangeNotifier {
    public static let shared = DataChangeNotifier()
    
    private init() {}
    
    // MARK: - Push 기반 알림 (단순화됨)
    
    /// 주차 세션이 시작되거나 종료되었음을 알립니다
    /// Push 기반에서는 App Group 스냅샷 업데이트로 대체
    public func notifySessionChanged() {
        print("📡 [DataChangeNotifier] 세션 변경 - App Group 스냅샷으로 처리")
        // 실제 Darwin Notification 제거 - App Group으로 대체됨
    }
    
    /// 주차비가 변경되었음을 알립니다
    /// Push 기반에서는 서버 Push + App Group 스냅샷으로 대체
    public func notifyFeeChanged() {
        print("📡 [DataChangeNotifier] 요금 변경 - Push + App Group 스냅샷으로 처리")
        // 실제 Darwin Notification 제거 - 서버 Push로 대체됨
    }
    
    // MARK: - 레거시 호환성 메서드 (빈 구현)
    
    /// 세션 변경 알림을 수신합니다 (레거시 호환성)
    /// - Parameter handler: 더 이상 사용되지 않음
    @available(*, deprecated, message: "Push 기반 아키텍처에서는 포그라운드 보정 서비스 사용")
    public func observeSessionChanges(_ handler: @escaping () -> Void) {
        print("⚠️ [DataChangeNotifier] observeSessionChanges는 더 이상 사용되지 않습니다. ForegroundSyncService 사용하세요.")
    }
    
    /// 주차비 변경 알림을 수신합니다 (레거시 호환성)
    /// - Parameter handler: 더 이상 사용되지 않음
    @available(*, deprecated, message: "Push 기반 아키텍처에서는 포그라운드 보정 서비스 사용")
    public func observeFeeChanges(_ handler: @escaping () -> Void) {
        print("⚠️ [DataChangeNotifier] observeFeeChanges는 더 이상 사용되지 않습니다. ForegroundSyncService 사용하세요.")
    }
    
    /// 모든 주차 관련 변경 알림을 수신합니다 (레거시 호환성)
    /// - Parameter handler: 더 이상 사용되지 않음
    @available(*, deprecated, message: "Push 기반 아키텍처에서는 포그라운드 보정 서비스 사용")
    public func observeAllChanges(_ handler: @escaping () -> Void) {
        print("⚠️ [DataChangeNotifier] observeAllChanges는 더 이상 사용되지 않습니다. ForegroundSyncService 사용하세요.")
    }
}

// MARK: - 단순화된 편의 메서드
public extension DataChangeNotifier {
    /// 위젯 전용 업데이트 요청 (App Group 스냅샷 기반)
    func requestWidgetUpdate() {
        print("📲 [DataChangeNotifier] 위젯 업데이트 - App Group 스냅샷 사용")
        // Darwin Notification 대신 직접 위젯 갱신
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// 라이브 액티비티 전용 업데이트 요청 (서버 Push 기반)
    func requestLiveActivityUpdate() {
        print("📲 [DataChangeNotifier] Live Activity 업데이트 - 서버 Push 사용")
        // Darwin Notification 대신 서버 Push로 대체됨
    }
}

// MARK: - 마이그레이션 가이드
#if DEBUG
public extension DataChangeNotifier {
    /// Push 기반 아키텍처로의 마이그레이션 정보
    var migrationInfo: String {
        return """
        === Push 기반 아키텍처 마이그레이션 ===
        ❌ Darwin Notification 제거됨
        ✅ 서버 Push (ActivityKit) 사용
        ✅ App Group 스냅샷으로 위젯 동기화
        ✅ 포그라운드 보정 서비스 사용
        ========================================
        """
    }
    
    /// 더 이상 사용되지 않는 기능 경고
    func showDeprecationWarning() {
        print("""
        ⚠️  [DataChangeNotifier] 사용 중단 안내
        Darwin Notification 기반 동기화는 Push 기반으로 교체되었습니다:
        
        Before: DataChangeNotifier.shared.observeAllChanges { ... }
        After:  ForegroundSyncService.shared.performImmediateSync()
        
        자세한 내용은 리팩토링 가이드를 참조하세요.
        """)
    }
}
#endif