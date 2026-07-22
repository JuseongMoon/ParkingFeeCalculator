//
//  ParkingData.swift
//  ParkingData
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import ParkingDomain
import ParkingShared

// MARK: - Data Layer Public API
// 이 파일은 ParkingData 패키지의 공개 API를 정의합니다

/// 패키지 버전 정보
public enum ParkingDataVersion {
    public static let version = "1.0.0"
    public static let buildNumber = 1
}

// MARK: - Data Sources
// Data Source들은 각각의 파일에서 public으로 선언되어 있음
// - UserDefaultsDataSource (protocol)
// - AppGroupUserDefaultsDataSource, StandardUserDefaultsDataSource (implementations)
// - DataSourceError

// MARK: - Repository Implementations
// Repository 구현체들은 각각의 파일에서 public으로 선언되어 있음
// - ParkingLotRepositoryImpl
// - ParkingSessionRepositoryImpl
// - UserProfileRepositoryImpl

// MARK: - Entity Mappers
// Domain과 Legacy 모델 간 변환을 담당
// - EntityMapper (static methods)

// MARK: - Data Layer DI Configuration
/// Data Layer의 의존성 주입 설정
public struct DataLayerDIConfiguration: DIConfiguration {
    public init() {}

    public func registerDependencies(in container: DIContainer) {
        // Data Sources 등록
        container.registerSingleton(UserDefaultsDataSource.self) {
            AppGroupUserDefaultsDataSource()
        }

        // Repository 구현체들 등록
        container.registerSingleton(ParkingLotRepository.self) {
            ParkingLotRepositoryImpl(
                dataSource: container.forceResolve(UserDefaultsDataSource.self)
            )
        }

        container.registerSingleton(ParkingSessionRepository.self) {
            ParkingSessionRepositoryImpl(
                dataSource: container.forceResolve(UserDefaultsDataSource.self)
            )
        }

        container.registerSingleton(UserProfileRepository.self) {
            UserProfileRepositoryImpl(
                dataSource: container.forceResolve(UserDefaultsDataSource.self)
            )
        }

        print("📦 [DataLayer] Repository 의존성들 등록 완료")
    }
}

// MARK: - Data Layer Errors
/// Data Layer의 추가 에러 타입들
public enum DataLayerError: Error, Equatable {
    case mappingFailed(String)
    case repositoryUnavailable
    case dataCorrupted(String)

    public var localizedDescription: String {
        switch self {
        case .mappingFailed(let details):
            return "데이터 매핑 실패: \(details)"
        case .repositoryUnavailable:
            return "Repository를 사용할 수 없습니다"
        case .dataCorrupted(let details):
            return "데이터 손상: \(details)"
        }
    }
}