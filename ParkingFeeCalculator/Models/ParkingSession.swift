//
//  ParkingSession.swift
//  ParkingFeeCalculator
//
//  Created by GPT-5 on 8/13/25.
//

import Foundation

struct ParkingTariff: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var baseFee: Int
    var baseMinutes: Int
    var unitFee: Int
    var unitMinutes: Int
    var maxFee: Int?
    // 추가 항목: 한국 주차장 요금 사례 반영
    var freeMinutes: Int = 0
    var dailyMaxFee: Int? = nil
    var nightFlatFee: Int? = nil
    // 24시간 기준 시각(0~23)
    var nightStartHour: Int? = nil
    var nightEndHour: Int? = nil
}

struct ParkingSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var startedAt: Date
    var tariff: ParkingTariff
}


