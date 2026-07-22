//
//  UserDefaultsDataSource.swift
//  ParkingData
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine
import ParkingShared

/// UserDefaults 기반 데이터 소스 인터페이스
public protocol UserDefaultsDataSource {
    /// 데이터를 저장합니다
    func save<T: Codable>(_ data: T, forKey key: String) -> Result<Void, DataSourceError>

    /// 데이터를 로드합니다
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> Result<T?, DataSourceError>

    /// 데이터를 삭제합니다
    func remove(forKey key: String) -> Result<Void, DataSourceError>

    /// 키 존재 여부를 확인합니다
    func exists(forKey key: String) -> Bool

    /// 데이터 변경을 관찰합니다
    func publisher<T: Codable>(for type: T.Type, key: String) -> AnyPublisher<T?, DataSourceError>
}

/// App Group UserDefaults 데이터 소스 구현
public final class AppGroupUserDefaultsDataSource: UserDefaultsDataSource {
    private let userDefaults: UserDefaults
    private let changeSubject = PassthroughSubject<String, Never>()

    public init(suiteName: String = AppGroupConstants.suiteName) {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            fatalError("App Group UserDefaults를 초기화할 수 없습니다: \(suiteName)")
        }
        self.userDefaults = userDefaults
    }

    public func save<T: Codable>(_ data: T, forKey key: String) -> Result<Void, DataSourceError> {
        do {
            let encodedData = try JSONEncoder().encode(data)
            userDefaults.set(encodedData, forKey: key)
            userDefaults.synchronize()

            changeSubject.send(key)
            print("✅ [AppGroupUserDefaults] 데이터 저장 완료: \(key)")

            return .success(())
        } catch {
            print("❌ [AppGroupUserDefaults] 데이터 저장 실패: \(key), 에러: \(error)")
            return .failure(.encodingFailed(error))
        }
    }

    public func load<T: Codable>(_ type: T.Type, forKey key: String) -> Result<T?, DataSourceError> {
        guard let data = userDefaults.data(forKey: key) else {
            return .success(nil)
        }

        do {
            let decoded = try JSONDecoder().decode(type, from: data)
            return .success(decoded)
        } catch {
            print("❌ [AppGroupUserDefaults] 데이터 로드 실패: \(key), 에러: \(error)")
            return .failure(.decodingFailed(error))
        }
    }

    public func remove(forKey key: String) -> Result<Void, DataSourceError> {
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()

        changeSubject.send(key)
        print("🗑 [AppGroupUserDefaults] 데이터 삭제 완료: \(key)")

        return .success(())
    }

    public func exists(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }

    public func publisher<T: Codable>(for type: T.Type, key: String) -> AnyPublisher<T?, DataSourceError> {
        return changeSubject
            .filter { $0 == key }
            .map { _ in self.load(type, forKey: key) }
            .compactMap { result in
                switch result {
                case .success(let data):
                    return data
                case .failure(let error):
                    print("⚠️ [AppGroupUserDefaults] Publisher 에러: \(error)")
                    return nil
                }
            }
            .setFailureType(to: DataSourceError.self)
            .eraseToAnyPublisher()
    }
}

/// 표준 UserDefaults 데이터 소스 구현 (fallback용)
public final class StandardUserDefaultsDataSource: UserDefaultsDataSource {
    private let userDefaults: UserDefaults
    private let changeSubject = PassthroughSubject<String, Never>()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func save<T: Codable>(_ data: T, forKey key: String) -> Result<Void, DataSourceError> {
        do {
            let encodedData = try JSONEncoder().encode(data)
            userDefaults.set(encodedData, forKey: key)

            changeSubject.send(key)
            print("✅ [StandardUserDefaults] 데이터 저장 완료: \(key)")

            return .success(())
        } catch {
            print("❌ [StandardUserDefaults] 데이터 저장 실패: \(key), 에러: \(error)")
            return .failure(.encodingFailed(error))
        }
    }

    public func load<T: Codable>(_ type: T.Type, forKey key: String) -> Result<T?, DataSourceError> {
        guard let data = userDefaults.data(forKey: key) else {
            return .success(nil)
        }

        do {
            let decoded = try JSONDecoder().decode(type, from: data)
            return .success(decoded)
        } catch {
            print("❌ [StandardUserDefaults] 데이터 로드 실패: \(key), 에러: \(error)")
            return .failure(.decodingFailed(error))
        }
    }

    public func remove(forKey key: String) -> Result<Void, DataSourceError> {
        userDefaults.removeObject(forKey: key)

        changeSubject.send(key)
        print("🗑 [StandardUserDefaults] 데이터 삭제 완료: \(key)")

        return .success(())
    }

    public func exists(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }

    public func publisher<T: Codable>(for type: T.Type, key: String) -> AnyPublisher<T?, DataSourceError> {
        return changeSubject
            .filter { $0 == key }
            .map { _ in self.load(type, forKey: key) }
            .compactMap { result in
                switch result {
                case .success(let data):
                    return data
                case .failure(let error):
                    print("⚠️ [StandardUserDefaults] Publisher 에러: \(error)")
                    return nil
                }
            }
            .setFailureType(to: DataSourceError.self)
            .eraseToAnyPublisher()
    }
}

/// Data Source 에러 타입
public enum DataSourceError: Error, Equatable {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case notFound(String)
    case accessDenied

    public static func == (lhs: DataSourceError, rhs: DataSourceError) -> Bool {
        switch (lhs, rhs) {
        case (.encodingFailed, .encodingFailed),
             (.decodingFailed, .decodingFailed),
             (.accessDenied, .accessDenied):
            return true
        case (.notFound(let lhsKey), .notFound(let rhsKey)):
            return lhsKey == rhsKey
        default:
            return false
        }
    }

    public var localizedDescription: String {
        switch self {
        case .encodingFailed(let error):
            return "인코딩 실패: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "디코딩 실패: \(error.localizedDescription)"
        case .notFound(let key):
            return "데이터를 찾을 수 없음: \(key)"
        case .accessDenied:
            return "접근 권한이 거부되었습니다"
        }
    }
}