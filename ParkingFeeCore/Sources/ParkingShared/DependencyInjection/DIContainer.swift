//
//  DIContainer.swift
//  ParkingShared
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation

/// 의존성 주입 컨테이너 인터페이스
public protocol DIContainer {
    /// 의존성을 등록합니다
    func register<T>(_ type: T.Type, factory: @escaping () -> T)

    /// 싱글톤으로 의존성을 등록합니다
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T)

    /// 의존성을 해결합니다
    func resolve<T>(_ type: T.Type) -> T?

    /// 의존성을 해결합니다 (강제)
    func forceResolve<T>(_ type: T.Type) -> T
}

/// 기본 의존성 주입 컨테이너 구현
public final class DefaultDIContainer: DIContainer {
    public static let shared = DefaultDIContainer()

    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var singletonFactories: [String: () -> Any] = [:]

    private init() {}

    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }

    public func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        singletonFactories[key] = factory
    }

    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)

        // 싱글톤 먼저 확인
        if let singleton = singletons[key] as? T {
            return singleton
        }

        // 싱글톤 팩토리 확인
        if let factory = singletonFactories[key] {
            let instance = factory() as! T
            singletons[key] = instance
            return instance
        }

        // 일반 팩토리 확인
        if let factory = factories[key] {
            return factory() as? T
        }

        return nil
    }

    public func forceResolve<T>(_ type: T.Type) -> T {
        guard let instance = resolve(type) else {
            fatalError("의존성을 해결할 수 없습니다: \(type)")
        }
        return instance
    }
}

// MARK: - Property Wrapper for Dependency Injection

/// 의존성 주입을 위한 Property Wrapper
@propertyWrapper
public struct Injected<T> {
    private let container: DIContainer

    public init(container: DIContainer = DefaultDIContainer.shared) {
        self.container = container
    }

    public var wrappedValue: T {
        return container.forceResolve(T.self)
    }
}

/// 옵셔널 의존성 주입을 위한 Property Wrapper
@propertyWrapper
public struct OptionalInjected<T> {
    private let container: DIContainer

    public init(container: DIContainer = DefaultDIContainer.shared) {
        self.container = container
    }

    public var wrappedValue: T? {
        return container.resolve(T.self)
    }
}

// MARK: - DI Configuration Protocol

/// DI 설정 프로토콜
public protocol DIConfiguration {
    /// 의존성들을 등록합니다
    func registerDependencies(in container: DIContainer)
}