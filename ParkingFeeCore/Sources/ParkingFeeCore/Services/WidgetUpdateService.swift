//
//  WidgetUpdateService.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/26/25.
//

import Foundation
import WidgetKit

/// 위젯 업데이트를 관리하는 서비스
public final class WidgetUpdateService {
    public static let shared = WidgetUpdateService()
    
    private init() {}
    
    /// 모든 위젯을 리로드합니다 (이벤트 발생 시)
    public func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        print("📱 [Widget] 모든 위젯 타임라인 리로드 요청")
    }
    
    /// 특정 위젯을 리로드합니다
    public func reloadWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        print("📱 [Widget] '\(kind)' 위젯 타임라인 리로드 요청")
    }
    
    /// 앱이 포그라운드로 돌아왔을 때 호출
    public func handleAppDidBecomeActive() {
        if ParkingSessionManager.shared.isSessionActive {
            reloadAllWidgets()
            print("📱 [Widget] 앱 활성화 - 위젯 리로드")
        }
    }
    
    /// 주차 세션이 시작되었을 때 호출
    public func handleSessionStarted() {
        reloadAllWidgets()
        print("📱 [Widget] 세션 시작 - 위젯 리로드")
    }
    
    /// 주차 세션이 종료되었을 때 호출
    public func handleSessionEnded() {
        reloadAllWidgets()
        print("📱 [Widget] 세션 종료 - 위젯 리로드")
    }
    
    /// 설정이 변경되었을 때 호출 (쿠폰, 할인 등)
    public func handleSettingsChanged() {
        if ParkingSessionManager.shared.isSessionActive {
            reloadAllWidgets()
            print("📱 [Widget] 설정 변경 - 위젯 리로드")
        }
    }
}