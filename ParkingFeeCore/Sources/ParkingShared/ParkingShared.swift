//
//  ParkingShared.swift
//  ParkingShared
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation

// MARK: - ParkingShared Package Public API
// 이 파일은 ParkingShared 패키지의 공개 API를 정의합니다

/// 패키지 버전 정보
public enum ParkingSharedVersion {
    public static let version = "1.0.0"
    public static let buildNumber = 1
}

// MARK: - Dependency Injection
// DI 관련 컴포넌트들은 각각의 파일에서 public으로 선언되어 있음
// - DIContainer, DefaultDIContainer
// - DIConfiguration, DIConfigurator
// - @Injected, @OptionalInjected Property Wrappers
// - DIEnvironment 환경별 설정

// MARK: - Shared Utilities (Future)
/// 공통 유틸리티들이 추가될 때 이곳에서 관리
/// 예: Extensions, Formatters, Constants 등

// MARK: - App Groups Support
/// App Groups 지원을 위한 상수들
public enum AppGroupConstants {
    public static let suiteName = "group.com.ScienceFiction.ParkingFeeCalculator"

    public enum Keys {
        public static let parkingLots = "savedParkingLots"
        public static let currentSession = "currentParkingSession"
        public static let userProfile = "userProfile"
        public static let vehicleProfile = "vehicleProfile"
        public static let driverProfile = "driverProfile"
    }
}

// MARK: - Shared Extensions (Future)
// 공통으로 사용될 Extension들이 여기에 추가될 예정