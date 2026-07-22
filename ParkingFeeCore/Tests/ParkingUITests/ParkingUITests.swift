//
//  ParkingUITests.swift
//  ParkingUITests
//
//  Created by ClaudeCode on 9/16/25.
//

import XCTest
@testable import ParkingUI
@testable import ParkingDomain

final class ParkingUITests: XCTestCase {

    func testUILayerExists() throws {
        // 기본적인 UI Layer 존재 확인 테스트
        XCTAssertNotNil(ParkingUIVersion.version)
        XCTAssertEqual(ParkingUIVersion.version, "1.0.0")
    }
}