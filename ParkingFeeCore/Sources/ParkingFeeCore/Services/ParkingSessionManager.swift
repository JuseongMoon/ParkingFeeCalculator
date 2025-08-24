//
//  ParkingSessionManager.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/24/25.
//

import Foundation

/// 주차 세션을 관리하고 App Groups 간 데이터를 동기화하는 매니저
public final class ParkingSessionManager {
    public static let shared = ParkingSessionManager()
    
    private let userDefaults: UserDefaults?
    private let sessionKey = "currentParkingSession"
    private let lastFeeKey = "lastCalculatedFee"
    private let appGroupIdentifier = "group.com.ScienceFiction.ParkingFeeCalculator"
    
    private init() {
        self.userDefaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Session Management
    
    /// 새 주차 세션을 시작합니다
    /// - Parameter session: 시작할 주차 세션
    public func startSession(_ session: SharedParkingSession) {
        saveCurrentSession(session)
        updateLastFee(session.currentFee)
        DataChangeNotifier.shared.notifySessionChanged()
    }
    
    /// 현재 주차 세션을 종료합니다
    public func endSession() {
        clearCurrentSession()
        clearLastFee()
        DataChangeNotifier.shared.notifySessionChanged()
    }
    
    /// 현재 주차 세션을 가져옵니다
    /// - Returns: 현재 활성 주차 세션, 없으면 nil
    public func currentSession() -> SharedParkingSession? {
        return loadCurrentSession()
    }
    
    /// 주차 세션이 활성 상태인지 확인합니다
    public var isSessionActive: Bool {
        return currentSession() != nil
    }
    
    /// 세션의 추가 무료시간을 업데이트합니다
    /// - Parameter additionalFreeMinutes: 새로운 추가 무료시간 (분)
    public func updateAdditionalFreeMinutes(_ additionalFreeMinutes: Int) {
        guard let session = currentSession() else { return }
        
        // 새로운 세션 생성 (불변 구조체이므로)
        let updatedSession = SharedParkingSession(
            startTime: session.startTime,
            parkingLot: session.parkingLot,
            vehicle: session.vehicle,
            driver: session.driver,
            additionalFreeMinutes: additionalFreeMinutes
        )
        
        saveCurrentSession(updatedSession)
        updateLastFee(updatedSession.currentFee)
        DataChangeNotifier.shared.notifyFeeChanged()
    }
    
    /// 현재 주차비를 업데이트합니다 (메인 앱에서 타이머 기반 업데이트용)
    /// - Parameter fee: 계산된 주차비
    public func updateCurrentFee(_ fee: Int) {
        updateLastFee(fee)
        DataChangeNotifier.shared.notifyFeeChanged()
    }
    
    // MARK: - Data Access
    
    /// 마지막 계산된 주차비를 가져옵니다 (위젯/라이브액티비티용)
    public func getLastCalculatedFee() -> Int {
        return userDefaults?.integer(forKey: lastFeeKey) ?? 0
    }
    
    // MARK: - Private Methods
    
    private func saveCurrentSession(_ session: SharedParkingSession) {
        guard let userDefaults = userDefaults else {
            print("❌ [ParkingSessionManager] App Group UserDefaults 사용 불가")
            return
        }
        
        do {
            let sessionDict = try session.toDictionary()
            let data = try JSONSerialization.data(withJSONObject: sessionDict)
            userDefaults.set(data, forKey: sessionKey)
            userDefaults.synchronize()
            print("✅ [ParkingSessionManager] 세션 저장 완료: \(session.parkingLot.name)")
        } catch {
            print("❌ [ParkingSessionManager] 세션 저장 실패: \(error)")
        }
    }
    
    private func loadCurrentSession() -> SharedParkingSession? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: sessionKey) else {
            return nil
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let sessionDict = json else { return nil }
            
            let session = try SharedParkingSession.fromDictionary(sessionDict)
            return session
        } catch {
            print("❌ [ParkingSessionManager] 세션 로드 실패: \(error)")
            return nil
        }
    }
    
    private func clearCurrentSession() {
        userDefaults?.removeObject(forKey: sessionKey)
        userDefaults?.synchronize()
        print("✅ [ParkingSessionManager] 세션 삭제 완료")
    }
    
    private func updateLastFee(_ fee: Int) {
        userDefaults?.set(fee, forKey: lastFeeKey)
        userDefaults?.synchronize()
    }
    
    private func clearLastFee() {
        userDefaults?.removeObject(forKey: lastFeeKey)
        userDefaults?.synchronize()
    }
}

// MARK: - Convenience Methods
public extension ParkingSessionManager {
    /// 현재 세션의 경과 시간을 가져옵니다
    var currentElapsedTime: TimeInterval {
        return currentSession()?.elapsedTime ?? 0
    }
    
    /// 현재 세션의 주차장 이름을 가져옵니다
    var currentParkingLotName: String {
        return currentSession()?.parkingLot.name ?? ""
    }
    
    /// 현재 세션의 시작 시간을 가져옵니다
    var currentStartTime: Date? {
        return currentSession()?.startTime
    }
    
    /// 현재 세션의 할인 정보를 가져옵니다
    var currentDiscountInfo: String? {
        return currentSession()?.discountInfo
    }
}