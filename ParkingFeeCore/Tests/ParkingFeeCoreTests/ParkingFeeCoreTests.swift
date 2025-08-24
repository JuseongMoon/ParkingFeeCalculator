//
//  ParkingFeeCoreTests.swift
//  ParkingFeeCoreTests
//
//  Created by 문주성 on 8/24/25.
//

import XCTest
@testable import ParkingFeeCore

final class ParkingFeeCoreTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPackageVersion() throws {
        // 패키지 버전 확인
        XCTAssertEqual(ParkingFeeCoreVersion.version, "1.0.0")
        XCTAssertEqual(ParkingFeeCoreVersion.buildNumber, 1)
    }
    
    func testTimeIntervalFormatting() throws {
        // TimeInterval 포맷팅 테스트
        let thirtyMinutes: TimeInterval = 1800
        XCTAssertEqual(thirtyMinutes.koreanTimeFormat, "30분")
        
        let oneHour: TimeInterval = 3600
        XCTAssertEqual(oneHour.koreanTimeFormat, "1시간")
        
        let oneHourThirtyMinutes: TimeInterval = 5400
        XCTAssertEqual(oneHourThirtyMinutes.koreanTimeFormat, "1시간 30분")
        
        let thirtySeconds: TimeInterval = 30
        XCTAssertEqual(thirtySeconds.koreanTimeFormat, "1분 미만")
    }
    
    func testVehicleProfileCreation() throws {
        // VehicleProfile 생성 테스트
        let vehicle = VehicleProfile(vehicleSize: .light, isElectric: true)
        
        XCTAssertEqual(vehicle.vehicleSize, .light)
        XCTAssertTrue(vehicle.isElectric)
        XCTAssertTrue(vehicle.isEcoFriendly)
        XCTAssertEqual(vehicle.displayName, "경차")
    }
    
    func testDriverProfileCreation() throws {
        // DriverProfile 생성 테스트
        let driver = DriverProfile(isDisabled: true, disabilityLevel: .severe)
        
        XCTAssertTrue(driver.isDisabled)
        XCTAssertEqual(driver.disabilityLevel, .severe)
        XCTAssertTrue(driver.hasAnySpecialCondition)
        XCTAssertEqual(driver.specialConditionsCount, 1)
    }
}