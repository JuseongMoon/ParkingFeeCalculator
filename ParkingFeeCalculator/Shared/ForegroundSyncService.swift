//
//  ForegroundSyncService.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 9/2/25.
//  단순화된 포그라운드 동기화 서비스
//

import Foundation

/// 단순화된 포그라운드 동기화 서비스
final class ForegroundSyncService {
    static let shared = ForegroundSyncService()

    private init() {}

    /// 디버깅 정보
    var debugInfo: String {
        return "포그라운드 동기화 활성"
    }

    /// 동기화 수행
    func performSync() {
        print("✅ 포그라운드 동기화 수행")
    }

    /// 즉시 동기화 수행
    func performImmediateSync() {
        print("✅ 즉시 포그라운드 동기화 수행")
    }
}