//
//  PushTokenManager.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 9/2/25.
//

import ActivityKit
import Foundation
import ParkingFeeCore

/// ActivityKit Push Token 로테이션을 관리하고 서버와 동기화하는 매니저
@MainActor
final class PushTokenManager: ObservableObject {
    static let shared = PushTokenManager()
    
    private var currentActivity: Activity<ParkingAttributes>?
    private var tokenUpdateTask: Task<Void, Never>?
    
    private init() {}
    
    /// Live Activity 시작 시 Push Token 스트림을 구독합니다
    /// - Parameter activity: 시작된 Live Activity 인스턴스
    func startTokenMonitoring(for activity: Activity<ParkingAttributes>) {
        // 기존 모니터링 중단
        stopTokenMonitoring()
        
        self.currentActivity = activity
        
        // Push Token 업데이트 스트림 구독
        tokenUpdateTask = Task {
            for await pushToken in activity.pushTokenUpdates {
                await handleTokenUpdate(pushToken, for: activity)
            }
        }
        
        print("🔑 [PushTokenManager] Token 모니터링 시작 - Activity ID: \(activity.id)")
    }
    
    /// Push Token 모니터링을 중단합니다
    func stopTokenMonitoring() {
        tokenUpdateTask?.cancel()
        tokenUpdateTask = nil
        currentActivity = nil
        
        print("🔑 [PushTokenManager] Token 모니터링 중단")
    }
    
    /// 새로운 Push Token을 서버로 전송합니다
    /// - Parameters:
    ///   - pushToken: 새로 받은 Push Token
    ///   - activity: 해당 Live Activity 인스턴스
    private func handleTokenUpdate(_ pushToken: Data, for activity: Activity<ParkingAttributes>) async {
        let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
        
        print("🔑 [PushTokenManager] 새 Token 수신: \(tokenString.prefix(16))...")
        
        // 현재 세션 정보 가져오기
        guard let session = ParkingSessionManager.shared.currentSession() else {
            print("❌ [PushTokenManager] 활성 세션이 없어 Token 전송 실패")
            return
        }
        
        // 서버로 Token 전송
        do {
            await NetworkService.shared.updatePushToken(
                sessionId: session.sessionId,
                activityId: activity.id,
                pushToken: tokenString,
                bundleId: Bundle.main.bundleIdentifier ?? ""
            )
            
            print("✅ [PushTokenManager] Token 서버 전송 완료")
            
            // 로컬 저장 (디버깅/백업용)
            saveTokenLocally(tokenString, for: activity.id)
            
        } catch {
            print("❌ [PushTokenManager] Token 서버 전송 실패: \(error)")
            
            // 실패 시 재시도 스케줄링 (3초 후)
            Task {
                try? await Task.sleep(for: .seconds(3))
                await handleTokenUpdate(pushToken, for: activity)
            }
        }
    }
    
    /// Push Token을 로컬에 임시 저장합니다 (디버깅/백업용)
    /// - Parameters:
    ///   - token: Push Token 문자열
    ///   - activityId: Activity ID
    private func saveTokenLocally(_ token: String, for activityId: String) {
        guard let userDefaults = UserDefaults(suiteName: "group.com.ScienceFiction.ParkingFeeCalculator") else {
            return
        }
        
        let tokenInfo: [String: Any] = [
            "token": token,
            "activityId": activityId,
            "lastUpdated": Date().timeIntervalSince1970,
            "bundleId": Bundle.main.bundleIdentifier ?? ""
        ]
        
        userDefaults.set(tokenInfo, forKey: "lastPushToken")
        userDefaults.synchronize()
    }
    
    /// 현재 저장된 Push Token 정보를 가져옵니다 (디버깅용)
    var currentTokenInfo: [String: Any]? {
        guard let userDefaults = UserDefaults(suiteName: "group.com.ScienceFiction.ParkingFeeCalculator") else {
            return nil
        }
        
        return userDefaults.object(forKey: "lastPushToken") as? [String: Any]
    }
    
    /// 현재 Activity가 활성 상태인지 확인합니다
    var isMonitoring: Bool {
        return currentActivity != nil && tokenUpdateTask != nil
    }
    
    /// 디버깅용 정보를 반환합니다
    var debugInfo: String {
        guard let activity = currentActivity,
              let tokenInfo = currentTokenInfo else {
            return "Token 모니터링 비활성"
        }
        
        let lastUpdated = Date(timeIntervalSince1970: tokenInfo["lastUpdated"] as? TimeInterval ?? 0)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        return """
        Activity ID: \(activity.id)
        마지막 Token 업데이트: \(formatter.string(from: lastUpdated))
        Bundle ID: \(tokenInfo["bundleId"] as? String ?? "")
        """
    }
    
    deinit {
        stopTokenMonitoring()
    }
}

// MARK: - Network Service Extension
extension NetworkService {
    /// Push Token을 서버로 전송합니다
    /// - Parameters:
    ///   - sessionId: 주차 세션 ID
    ///   - activityId: Live Activity ID
    ///   - pushToken: Push Token 문자열
    ///   - bundleId: 앱 Bundle ID
    func updatePushToken(
        sessionId: String,
        activityId: String,
        pushToken: String,
        bundleId: String
    ) async throws {
        // TODO: 실제 Lambda API 엔드포인트로 교체
        let endpoint = "https://your-api-gateway.amazonaws.com/prod/sessions/\(sessionId)/push-token"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let payload: [String: Any] = [
            "activityId": activityId,
            "pushToken": pushToken,
            "bundleId": bundleId,
            "topic": "\(bundleId).push-type.liveactivity",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionId, forHTTPHeaderField: "X-Session-Id") // Idempotency
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.serverError
        }
    }
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case serverError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .serverError:
            return "서버 오류가 발생했습니다"
        case .noData:
            return "응답 데이터가 없습니다"
        }
    }
}