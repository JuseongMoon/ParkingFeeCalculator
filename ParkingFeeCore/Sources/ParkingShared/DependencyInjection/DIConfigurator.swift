//
//  DIConfigurator.swift
//  ParkingShared
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation

/// 의존성 주입 설정 관리자
public final class DIConfigurator {
    public static let shared = DIConfigurator()

    private let container: DIContainer
    private var isConfigured = false

    private init(container: DIContainer = DefaultDIContainer.shared) {
        self.container = container
    }

    /// 모든 의존성을 설정합니다
    public func configure(with configurations: [DIConfiguration]) {
        guard !isConfigured else {
            print("⚠️ [DIConfigurator] 의존성이 이미 설정되었습니다.")
            return
        }

        print("🚀 [DIConfigurator] 의존성 주입 설정 시작...")

        for configuration in configurations {
            configuration.registerDependencies(in: container)
        }

        isConfigured = true
        print("✅ [DIConfigurator] 의존성 주입 설정 완료")
    }

    /// 테스트용 의존성 재설정
    public func reconfigureForTesting(with configurations: [DIConfiguration]) {
        clearAllDependencies()
        isConfigured = false
        configure(with: configurations)
    }

    /// 모든 의존성을 정리합니다 (테스트용)
    private func clearAllDependencies() {
        // DefaultDIContainer의 내부 상태를 리셋할 수 있도록 메서드 추가 필요
        // 지금은 단순히 플래그만 리셋
        isConfigured = false
    }
}

// MARK: - Environment-based Configuration

/// 환경별 DI 설정
public enum DIEnvironment {
    case production
    case development
    case testing

    public var configurations: [DIConfiguration] {
        switch self {
        case .production:
            return [
                ProductionDIConfiguration()
            ]
        case .development:
            return [
                DevelopmentDIConfiguration()
            ]
        case .testing:
            return [
                TestingDIConfiguration()
            ]
        }
    }
}

// MARK: - Built-in Configurations

/// 프로덕션 환경 DI 설정
public struct ProductionDIConfiguration: DIConfiguration {
    public init() {}

    public func registerDependencies(in container: DIContainer) {
        // Import 추가가 필요하지만 현재는 조건부로 구현
        print("📦 [Production] Repository 의존성들 등록 시작")
        // ParkingAppDIConfiguration().registerDependencies(in: container)
    }
}

/// 개발 환경 DI 설정
public struct DevelopmentDIConfiguration: DIConfiguration {
    public init() {}

    public func registerDependencies(in container: DIContainer) {
        print("🛠 [Development] Repository 의존성들 등록 시작")
        // 개발용 설정과 함께 전체 앱 설정 등록
        // ParkingAppDIConfiguration().registerDependencies(in: container)
    }
}

/// 테스트 환경 DI 설정
public struct TestingDIConfiguration: DIConfiguration {
    public init() {}

    public func registerDependencies(in container: DIContainer) {
        // Mock 구현체들이 여기서 등록됨
        print("🧪 [Testing] Mock Repository들 등록 예정")
    }
}

// MARK: - DI Extensions

public extension DIContainer {
    /// 빠른 등록을 위한 확장 메서드
    func registerTransient<T>(_ type: T.Type, factory: @escaping () -> T) {
        register(type, factory: factory)
    }
}