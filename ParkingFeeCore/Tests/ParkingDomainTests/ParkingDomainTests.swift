//
//  ParkingDomainTests.swift
//  ParkingDomainTests
//
//  Created by ClaudeCode on 9/16/25.
//

import XCTest
@testable import ParkingDomain

final class ParkingDomainTests: XCTestCase {

    func testParkingLotEntityCreation() throws {
        let basicRules = BasicFeeRules(
            initialFee: 1000,
            initialMinutes: 30,
            additionalFee: 500,
            additionalMinutes: 15,
            freeMinutes: 10
        )

        let feeRules = FeeCalculationRules(basicRules: basicRules)
        let discountRules = DiscountRules()

        let entity = ParkingLotEntity(
            name: "테스트 주차장",
            address: "서울시 강남구",
            feeCalculationRules: feeRules,
            discountRules: discountRules
        )

        XCTAssertEqual(entity.name, "테스트 주차장")
        XCTAssertEqual(entity.address, "서울시 강남구")
        XCTAssertEqual(entity.displayName, "테스트 주차장")
        XCTAssertTrue(entity.isComplete)
    }

    func testVehicleProfileCreation() throws {
        let profile = VehicleProfile(size: .light, fuelType: .electric)

        XCTAssertEqual(profile.size, .light)
        XCTAssertEqual(profile.fuelType, .electric)
        XCTAssertTrue(profile.isEcoFriendly)
        XCTAssertTrue(profile.isElectric)
        XCTAssertFalse(profile.isHydrogen)
    }

    func testDriverProfileCreation() throws {
        let conditions: Set<SpecialCondition> = [.severeDisability, .senior]
        let profile = DriverProfile(specialConditions: conditions)

        XCTAssertTrue(profile.hasAnySpecialCondition)
        XCTAssertTrue(profile.isDisabled)
        XCTAssertTrue(profile.isSenior)
        XCTAssertEqual(profile.disabilityLevel, .severe)
        XCTAssertTrue(profile.displayName.contains("중증 장애인"))
    }
}