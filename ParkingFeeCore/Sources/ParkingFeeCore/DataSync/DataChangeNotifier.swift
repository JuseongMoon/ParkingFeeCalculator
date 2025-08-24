//
//  DataChangeNotifier.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/24/25.
//

import Foundation

/// Darwin Notification을 사용하여 앱, 위젯, 라이브액티비티 간 데이터 변경을 알리는 클래스
public final class DataChangeNotifier {
    public static let shared = DataChangeNotifier()
    
    // Notification Names
    private let sessionChangedNotification = "com.sciencefiction.ParkingFeeCalculator.sessionChanged" as CFString
    private let feeChangedNotification = "com.sciencefiction.ParkingFeeCalculator.feeChanged" as CFString
    
    private var observers: [String: [() -> Void]] = [:]
    
    private init() {}
    
    // MARK: - Notification Posting
    
    /// 주차 세션이 시작되거나 종료되었음을 알립니다
    public func notifySessionChanged() {
        postNotification(sessionChangedNotification)
    }
    
    /// 주차비가 변경되었음을 알립니다 (1분마다 또는 설정 변경 시)
    public func notifyFeeChanged() {
        postNotification(feeChangedNotification)
    }
    
    // MARK: - Notification Observing
    
    /// 세션 변경 알림을 수신합니다
    /// - Parameter handler: 세션 변경 시 호출될 핸들러
    public func observeSessionChanges(_ handler: @escaping () -> Void) {
        observeNotification(sessionChangedNotification, handler: handler)
    }
    
    /// 주차비 변경 알림을 수신합니다
    /// - Parameter handler: 주차비 변경 시 호출될 핸들러
    public func observeFeeChanges(_ handler: @escaping () -> Void) {
        observeNotification(feeChangedNotification, handler: handler)
    }
    
    /// 모든 주차 관련 변경 알림을 수신합니다
    /// - Parameter handler: 변경 시 호출될 핸들러
    public func observeAllChanges(_ handler: @escaping () -> Void) {
        observeSessionChanges(handler)
        observeFeeChanges(handler)
    }
    
    // MARK: - Private Methods
    
    private func postNotification(_ name: CFString) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(name),
            nil,
            nil,
            true
        )
        
        let nameString = String(name)
        print("📡 [DataChangeNotifier] 알림 발송: \(nameString)")
    }
    
    private func observeNotification(_ name: CFString, handler: @escaping () -> Void) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let nameString = String(name)
        
        // 기존 observer가 있다면 추가
        if observers[nameString] == nil {
            observers[nameString] = []
        }
        observers[nameString]?.append(handler)
        
        // Darwin Notification 콜백 설정
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        CFNotificationCenterAddObserver(
            center,
            observer,
            { (center, observer, name, object, userInfo) in
                guard let observer = observer,
                      let name = name else { return }
                
                let notifier = Unmanaged<DataChangeNotifier>.fromOpaque(observer).takeUnretainedValue()
                let nameString = String(name.rawValue)
                
                print("📡 [DataChangeNotifier] 알림 수신: \(nameString)")
                
                // 메인 큐에서 핸들러 실행
                DispatchQueue.main.async {
                    notifier.observers[nameString]?.forEach { $0() }
                }
            },
            name,
            nil,
            .deliverImmediately
        )
        
        print("📡 [DataChangeNotifier] 알림 관찰 시작: \(nameString)")
    }
}

// MARK: - Convenience Methods
public extension DataChangeNotifier {
    /// 위젯 전용 업데이트 요청
    func requestWidgetUpdate() {
        notifyFeeChanged()
    }
    
    /// 라이브 액티비티 전용 업데이트 요청
    func requestLiveActivityUpdate() {
        notifyFeeChanged()
    }
}

// MARK: - Debug Helpers
#if DEBUG
public extension DataChangeNotifier {
    /// 테스트용 더미 알림 발송
    func sendTestNotification() {
        print("🧪 [DataChangeNotifier] 테스트 알림 발송")
        notifyFeeChanged()
    }
    
    /// 현재 등록된 observer 수 확인
    var observerCount: Int {
        return observers.values.reduce(0) { $0 + $1.count }
    }
}
#endif