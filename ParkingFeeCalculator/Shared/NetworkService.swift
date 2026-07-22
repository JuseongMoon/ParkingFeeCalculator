//
//  NetworkService.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 9/2/25.
//  단순화된 네트워크 서비스
//

import Foundation

/// 단순화된 네트워크 서비스
final class NetworkService {
    static let shared = NetworkService()

    private init() {}

    // MARK: - 기본 네트워크 메서드

    func createParkingSession(from session: SharedParkingSession) -> Result<String, Error> {
        // 간단한 세션 생성 로직
        print("✅ 주차 세션 생성: \(session.id)")
        return .success("세션 생성 완료")
    }

    func updateParkingFee(sessionId: UUID, fee: Int) -> Result<String, Error> {
        // 간단한 요금 업데이트 로직
        print("✅ 주차 요금 업데이트: \(sessionId) - \(fee)원")
        return .success("요금 업데이트 완료")
    }

    func endParkingSession(sessionId: UUID) -> Result<String, Error> {
        // 간단한 세션 종료 로직
        print("✅ 주차 세션 종료: \(sessionId)")
        return .success("세션 종료 완료")
    }
}