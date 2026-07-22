//
//  ParkingDataTests.swift
//  ParkingDataTests
//
//  Created by ClaudeCode on 9/16/25.
//

import XCTest
@testable import ParkingData
@testable import ParkingDomain

final class ParkingDataTests: XCTestCase {

    func testDataLayerExists() throws {
        // 기본적인 Data Layer 존재 확인 테스트
        XCTAssertNotNil(ParkingDataVersion.version)
        XCTAssertEqual(ParkingDataVersion.version, "1.0.0")
    }
}