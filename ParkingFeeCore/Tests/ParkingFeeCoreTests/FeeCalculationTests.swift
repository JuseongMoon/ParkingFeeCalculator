//
//  FeeCalculationTests.swift
//  ParkingFeeCoreTests
//
//  Created by 문주성 on 8/24/25.
//

import XCTest
@testable import ParkingFeeCore

final class FeeCalculationTests: XCTestCase {
    
    var feeCalculationService: FeeCalculationService!
    var sessionManager: ParkingSessionManager!
    
    override func setUpWithError() throws {
        feeCalculationService = FeeCalculationService.shared
        sessionManager = ParkingSessionManager.shared
    }
    
    override func tearDownWithError() throws {
        // 테스트 후 세션 정리
        sessionManager.endSession()
    }
    
    // MARK: - 기본 주차비 계산 테스트
    
    func testBasicFeeCalculation() throws {
        // Given
        let parkingLot = createTestParkingLot()
        let vehicle = VehicleProfile()
        let driver = DriverProfile()
        let duration: TimeInterval = 3600 // 1시간
        
        // When
        let result = feeCalculationService.calculateFee(
            parkingLot: parkingLot,
            vehicle: vehicle,
            driver: driver,
            duration: duration
        )
        
        // Then
        XCTAssertEqual(result.finalFee, 5000) // 초기 30분 2000원 + 추가 30분(6*5분 단위) 3000원 = 5000원
    }
    
    func testFreeTimeCalculation() throws {
        // Given
        let parkingLot = createTestParkingLot(freeMinutes: 60)
        let vehicle = VehicleProfile()
        let driver = DriverProfile()
        let duration: TimeInterval = 1800 // 30분 (무료시간 60분 이하)
        
        // When
        let result = feeCalculationService.calculateFee(
            parkingLot: parkingLot,
            vehicle: vehicle,
            driver: driver,
            duration: duration
        )
        
        // Then
        XCTAssertEqual(result.finalFee, 0)
    }
    
    // MARK: - 할인 계산 테스트
    
    func testLightCarDiscount() throws {
        // Given
        let parkingLot = createTestParkingLot(lightCarDiscount: 50.0)
        let vehicle = VehicleProfile(vehicleSize: .light)
        let driver = DriverProfile()
        let duration: TimeInterval = 3600 // 1시간
        
        // When
        let result = feeCalculationService.calculateFee(
            parkingLot: parkingLot,
            vehicle: vehicle,
            driver: driver,
            duration: duration
        )
        
        // Then
        let expectedBaseFee = 5000
        let expectedDiscountedFee = Int(Double(expectedBaseFee) * 0.5) // 50% 할인
        XCTAssertEqual(result.finalFee, expectedDiscountedFee)
    }
    
    // MARK: - 세션 관리 테스트
    
    func testSessionCreationAndRetrieval() throws {
        // Given
        let session = createTestSession()
        
        // When
        sessionManager.startSession(session)
        let retrievedSession = sessionManager.currentSession()
        
        // Then
        XCTAssertNotNil(retrievedSession)
        XCTAssertEqual(retrievedSession?.parkingLot.name, session.parkingLot.name)
        XCTAssertTrue(sessionManager.isSessionActive)
    }
    
    func testSessionTermination() throws {
        // Given
        let session = createTestSession()
        sessionManager.startSession(session)
        
        // When
        sessionManager.endSession()
        
        // Then
        XCTAssertNil(sessionManager.currentSession())
        XCTAssertFalse(sessionManager.isSessionActive)
    }
    
    // MARK: - Helper Methods
    
    private func createTestParkingLot(
        initialFee: Int = 2000,
        initialMinutes: Int = 30,
        additionalFee: Int = 500,
        additionalMinutes: Int = 5,
        freeMinutes: Int = 0,
        lightCarDiscount: Double? = nil
    ) -> ParkingLotProfile {
        let feeCalculator = ParkingFeeCalculator(
            initialFee: initialFee,
            initialMinutes: initialMinutes,
            additionalFee: additionalFee,
            additionalMinutes: additionalMinutes,
            freeMinutes: freeMinutes
        )
        
        let discounts = SpecialConditionDiscounts(
            lightCarDiscountPercentage: lightCarDiscount
        )
        
        return ParkingLotProfile(
            name: "테스트 주차장",
            address: "서울시 테스트구",
            parkingFeeCalculator: feeCalculator,
            specialConditionDiscounts: discounts
        )
    }
    
    private func createTestSession() -> SharedParkingSession {
        let parkingLot = createTestParkingLot()
        let vehicle = VehicleProfile()
        let driver = DriverProfile()
        
        return SharedParkingSession(
            startTime: Date(),
            parkingLot: parkingLot,
            vehicle: vehicle,
            driver: driver
        )
    }
}