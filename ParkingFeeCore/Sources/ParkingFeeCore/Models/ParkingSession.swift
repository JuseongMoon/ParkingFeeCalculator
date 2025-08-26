//
//  ParkingSession.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/26/25.
//

import Foundation

/// 주차 세션 정보 (SharedParkingSession의 별칭)
public typealias ParkingSession = SharedParkingSession

/// 주차 세션의 상태
public enum ParkingSessionStatus: String, Codable, CaseIterable {
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .active:
            return "진행중"
        case .completed:
            return "완료"
        case .cancelled:
            return "취소"
        }
    }
}