//
//  AppGroupSnapshot.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 9/2/25.
//

import Foundation
import WidgetKit
// import ParkingFeeCore // 임시 제거

/// App Group을 통한 단일 진실원 데이터 스냅샷 관리
/// 위젯과 Live Activity 간 일관성 보장
final class AppGroupSnapshot {
    static let shared = AppGroupSnapshot()
    
    private let userDefaults: UserDefaults?
    private let appGroupIdentifier = "group.com.ScienceFiction.ParkingFeeCalculator"
    
    // 스냅샷 키들
    private let currentSessionKey = "snapshot_currentSession"
    private let lastCalculatedFeeKey = "snapshot_lastCalculatedFee"
    private let serverResponseKey = "snapshot_serverResponse"
    private let lastUpdateTimeKey = "snapshot_lastUpdateTime"
    
    private init() {
        self.userDefaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Session Snapshot
    
    /// 현재 세션 스냅샷을 저장합니다
    /// - Parameter session: 저장할 세션 정보
    func updateSessionSnapshot(_ session: SharedParkingSession) {
        guard let userDefaults = userDefaults else {
            print("❌ [AppGroupSnapshot] App Group UserDefaults 사용 불가")
            return
        }
        
        do {
            let sessionDict = try session.toDictionary()
            let data = try JSONSerialization.data(withJSONObject: sessionDict)
            
            userDefaults.set(data, forKey: currentSessionKey)
            userDefaults.set(Date().timeIntervalSince1970, forKey: lastUpdateTimeKey)
            userDefaults.synchronize()
            
            print("✅ [AppGroupSnapshot] 세션 스냅샷 저장 완료")
            
            // 위젯 타임라인 즉시 갱신
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            print("❌ [AppGroupSnapshot] 세션 스냅샷 저장 실패: \(error)")
        }
    }
    
    /// 현재 세션 스냅샷을 가져옵니다
    /// - Returns: 저장된 세션 정보
    func currentSessionSnapshot() -> SharedParkingSession? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: currentSessionKey) else {
            return nil
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let sessionDict = json else { return nil }
            
            return try SharedParkingSession.fromDictionary(sessionDict)
        } catch {
            print("❌ [AppGroupSnapshot] 세션 스냅샷 로드 실패: \(error)")
            return nil
        }
    }
    
    // MARK: - Fee Calculation Snapshot
    
    /// 최신 요금 계산 결과를 저장합니다 (위젯에서 사용)
    /// - Parameters:
    ///   - fee: 계산된 최종 요금
    ///   - discountInfo: 적용된 할인 정보
    ///   - calculatedAt: 계산 시점
    func updateFeeSnapshot(_ fee: Int, discountInfo: String?, calculatedAt: Date = Date()) {
        guard let userDefaults = userDefaults else { return }
        
        let feeSnapshot: [String: Any] = [
            "finalFee": fee,
            "discountInfo": discountInfo as Any,
            "calculatedAt": calculatedAt.timeIntervalSince1970,
            "isStale": false
        ]
        
        userDefaults.set(feeSnapshot, forKey: lastCalculatedFeeKey)
        userDefaults.set(Date().timeIntervalSince1970, forKey: lastUpdateTimeKey)
        userDefaults.synchronize()
        
        print("📸 [AppGroupSnapshot] 요금 스냅샷 업데이트: \(fee)원")
        
        // 위젯 즉시 갱신
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// 최신 요금 스냅샷을 가져옵니다
    /// - Returns: 요금 스냅샷 정보
    func currentFeeSnapshot() -> FeeSnapshot? {
        guard let userDefaults = userDefaults,
              let feeDict = userDefaults.object(forKey: lastCalculatedFeeKey) as? [String: Any] else {
            return nil
        }
        
        let finalFee = feeDict["finalFee"] as? Int ?? 0
        let discountInfo = feeDict["discountInfo"] as? String
        let calculatedAt = Date(timeIntervalSince1970: feeDict["calculatedAt"] as? TimeInterval ?? 0)
        let isStale = feeDict["isStale"] as? Bool ?? false
        
        return FeeSnapshot(
            finalFee: finalFee,
            discountInfo: discountInfo,
            calculatedAt: calculatedAt,
            isStale: isStale
        )
    }
    
    /// 요금 스냅샷을 오래된 상태로 마킹합니다 (5분 이상 지났을 때)
    func markFeeSnapshotAsStale() {
        guard let userDefaults = userDefaults,
              var feeDict = userDefaults.object(forKey: lastCalculatedFeeKey) as? [String: Any] else {
            return
        }
        
        feeDict["isStale"] = true
        userDefaults.set(feeDict, forKey: lastCalculatedFeeKey)
        userDefaults.synchronize()
        
        print("⏰ [AppGroupSnapshot] 요금 스냅샷을 오래된 상태로 마킹")
    }
    
    // MARK: - Server Response Snapshot
    
    /// 서버 응답을 저장합니다 (다음 스케줄 정보 등)
    /// - Parameter response: 서버 응답 데이터
    func updateServerResponse(_ response: ParkingSessionResponse) {
        guard let userDefaults = userDefaults else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(response)
            
            userDefaults.set(data, forKey: serverResponseKey)
            userDefaults.synchronize()
            
            print("🔄 [AppGroupSnapshot] 서버 응답 저장 완료")
            
        } catch {
            print("❌ [AppGroupSnapshot] 서버 응답 저장 실패: \(error)")
        }
    }
    
    /// 저장된 서버 응답을 가져옵니다
    /// - Returns: 서버 응답 데이터
    func serverResponse() -> ParkingSessionResponse? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: serverResponseKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ParkingSessionResponse.self, from: data)
        } catch {
            print("❌ [AppGroupSnapshot] 서버 응답 로드 실패: \(error)")
            return nil
        }
    }
    
    // MARK: - Cleanup
    
    /// 세션 종료 시 모든 스냅샷을 정리합니다
    func clearSession() {
        guard let userDefaults = userDefaults else { return }
        
        userDefaults.removeObject(forKey: currentSessionKey)
        userDefaults.removeObject(forKey: lastCalculatedFeeKey)
        userDefaults.removeObject(forKey: serverResponseKey)
        userDefaults.removeObject(forKey: lastUpdateTimeKey)
        userDefaults.synchronize()
        
        print("🧹 [AppGroupSnapshot] 모든 스냅샷 정리 완료")
        
        // 위젯 갱신 (빈 상태 표시)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Status & Debug
    
    /// 마지막 업데이트 시간을 반환합니다
    var lastUpdateTime: Date? {
        guard let userDefaults = userDefaults,
              let timestamp = userDefaults.object(forKey: lastUpdateTimeKey) as? TimeInterval else {
            return nil
        }
        
        return Date(timeIntervalSince1970: timestamp)
    }
    
    /// 스냅샷이 5분 이상 오래되었는지 확인합니다
    var isSnapshotStale: Bool {
        guard let lastUpdate = lastUpdateTime else { return true }
        
        return Date().timeIntervalSince(lastUpdate) > 300 // 5분
    }
    
    /// 디버깅용 정보를 반환합니다
    var debugInfo: String {
        let hasSession = currentSessionSnapshot() != nil
        let hasFee = currentFeeSnapshot() != nil
        let hasServerResponse = serverResponse() != nil
        let lastUpdate = lastUpdateTime?.description ?? "없음"
        
        return """
        세션: \(hasSession ? "있음" : "없음")
        요금: \(hasFee ? "있음" : "없음")
        서버 응답: \(hasServerResponse ? "있음" : "없음")
        마지막 업데이트: \(lastUpdate)
        오래된 상태: \(isSnapshotStale)
        """
    }
}

// MARK: - Fee Snapshot Model

struct FeeSnapshot {
    let finalFee: Int
    let discountInfo: String?
    let calculatedAt: Date
    let isStale: Bool
    
    /// 요금 정보가 최신인지 확인합니다 (1분 이내)
    var isFresh: Bool {
        return !isStale && Date().timeIntervalSince(calculatedAt) < 60
    }
    
    /// 위젯 표시용 포맷된 문자열
    var formattedFee: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "\(formatter.string(from: NSNumber(value: finalFee)) ?? "0")원"
    }
    
    /// 마지막 업데이트 시간 표시 문자열
    var lastUpdateDisplay: String {
        let elapsed = Date().timeIntervalSince(calculatedAt)
        let minutes = Int(elapsed / 60)
        
        if minutes < 1 {
            return "방금 전"
        } else if minutes < 60 {
            return "\(minutes)분 전"
        } else {
            let hours = minutes / 60
            return "\(hours)시간 전"
        }
    }
}