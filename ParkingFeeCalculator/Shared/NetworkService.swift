//
//  NetworkService.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 9/2/25.
//

import Foundation
import ParkingFeeCore

/// Lambda API와 통신하는 네트워크 서비스
final class NetworkService {
    static let shared = NetworkService()
    
    private let baseURL = "https://your-api-gateway.amazonaws.com/prod"
    private let session = URLSession.shared
    
    private init() {}
    
    /// 새 주차 세션을 시작합니다
    /// - Parameter sessionRequest: 세션 시작 요청 데이터
    /// - Returns: 생성된 세션 정보
    func startParkingSession(_ sessionRequest: ParkingSessionRequest) async throws -> ParkingSessionResponse {
        let endpoint = "\(baseURL)/sessions/start"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionRequest.idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(sessionRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("❌ [NetworkService] 세션 시작 실패: HTTP \(httpResponse.statusCode)")
            throw NetworkError.serverError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ParkingSessionResponse.self, from: data)
    }
    
    /// 주차 세션을 종료합니다
    /// - Parameter sessionId: 종료할 세션 ID
    func endParkingSession(_ sessionId: String) async throws {
        let endpoint = "\(baseURL)/sessions/\(sessionId)/end"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionId, forHTTPHeaderField: "Idempotency-Key")
        
        let payload = ["timestamp": Date().timeIntervalSince1970]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            print("❌ [NetworkService] 세션 종료 실패")
            throw NetworkError.serverError
        }
        
        print("✅ [NetworkService] 세션 종료 완료: \(sessionId)")
    }
}

// MARK: - Request/Response Models

struct ParkingSessionRequest: Codable {
    let sessionId: String
    let startTime: Date
    let parkingLotId: String
    let parkingLotName: String
    let vehicleProfile: VehicleProfileData
    let driverProfile: DriverProfileData
    let additionalFreeMinutes: Int
    let feeCalculatorConfig: FeeCalculatorConfig
    let idempotencyKey: String
    
    init(session: SharedParkingSession) {
        self.sessionId = session.sessionId
        self.startTime = session.startTime
        self.parkingLotId = session.parkingLot.id
        self.parkingLotName = session.parkingLot.name
        self.vehicleProfile = VehicleProfileData(session.vehicle)
        self.driverProfile = DriverProfileData(session.driver)
        self.additionalFreeMinutes = session.additionalFreeMinutes
        self.feeCalculatorConfig = FeeCalculatorConfig(session.parkingLot.parkingFeeCalculator)
        self.idempotencyKey = "start-\(session.sessionId)"
    }
}

struct ParkingSessionResponse: Codable {
    let sessionId: String
    let status: String
    let nextScheduleId: String?
    let nextChangeTime: Date?
}

// MARK: - Data Transfer Objects

struct VehicleProfileData: Codable {
    let type: String
    let isElectric: Bool
    let isCompact: Bool
    
    init(_ profile: VehicleProfile) {
        self.type = profile.type.rawValue
        self.isElectric = profile.isElectric
        self.isCompact = profile.isCompact
    }
}

struct DriverProfileData: Codable {
    let hasDisabilityDiscount: Bool
    let hasSeniorDiscount: Bool
    let hasLowIncomeDiscount: Bool
    let hasMultiChildDiscount: Bool
    let hasNationalMeritDiscount: Bool
    
    init(_ profile: DriverProfile) {
        self.hasDisabilityDiscount = profile.hasDisabilityDiscount
        self.hasSeniorDiscount = profile.hasSeniorDiscount
        self.hasLowIncomeDiscount = profile.hasLowIncomeDiscount
        self.hasMultiChildDiscount = profile.hasMultiChildDiscount
        self.hasNationalMeritDiscount = profile.hasNationalMeritDiscount
    }
}

struct FeeCalculatorConfig: Codable {
    let freeMinutes: Int
    let initialMinutes: Int
    let initialFee: Int
    let additionalMinutes: Int
    let additionalFee: Int
    let maxFee: Int?
    let hasNightRate: Bool
    let nightStartHour: Int?
    let nightEndHour: Int?
    let nightInitialFee: Int?
    let nightAdditionalFee: Int?
    
    init(_ calculator: ParkingFeeCalculator) {
        self.freeMinutes = calculator.freeMinutes
        self.initialMinutes = calculator.initialMinutes
        self.initialFee = calculator.initialFee
        self.additionalMinutes = calculator.additionalMinutes
        self.additionalFee = calculator.additionalFee
        self.maxFee = calculator.maxFee
        self.hasNightRate = calculator.hasNightRate
        self.nightStartHour = calculator.nightStartHour
        self.nightEndHour = calculator.nightEndHour
        self.nightInitialFee = calculator.nightInitialFee
        self.nightAdditionalFee = calculator.nightAdditionalFee
    }
}