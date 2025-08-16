//
//  TimerFormView.swift
//  ParkingFeeCalculator
//
//  Created by GPT-5 on 8/13/25.
//

import SwiftUI

struct TimerFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var baseFee: Int = 1000
    @State private var baseMinutes: Int = 30
    @State private var unitFee: Int = 500
    @State private var unitMinutes: Int = 10
    @State private var maxFee: Int = 10000
    @State private var freeMinutes: Int = 0
    @State private var dailyMaxFee: Int = 0
    @State private var nightFlatFee: Int = 0
    @State private var nightStartHour: Int = 22
    @State private var nightEndHour: Int = 7

    let onSave: (ParkingSession) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("주차장") {
                    TextField("이름(선택)", text: $name)
                }

                Section("요금표") {
                    Stepper(value: $baseFee, in: 0...100_000, step: 100) { row("기본요금", suffix: "원", value: baseFee) }
                    Stepper(value: $baseMinutes, in: 0...180, step: 5) { row("기본시간", suffix: "분", value: baseMinutes) }
                    Stepper(value: $unitFee, in: 0...20_000, step: 100) { row("추가요금", suffix: "원", value: unitFee) }
                    Stepper(value: $unitMinutes, in: 1...120, step: 1) { row("단위시간", suffix: "분", value: unitMinutes) }
                    Stepper(value: $maxFee, in: 0...200_000, step: 1000) { row("상한요금(세션)", suffix: "원", value: maxFee) }
                }

                Section("국내 사례 옵션") {
                    Stepper(value: $freeMinutes, in: 0...60, step: 5) { row("무료시간", suffix: "분", value: freeMinutes) }
                    Stepper(value: $dailyMaxFee, in: 0...200_000, step: 1000) { row("일일최대요금", suffix: "원", value: dailyMaxFee) }
                    Stepper(value: $nightFlatFee, in: 0...200_000, step: 1000) { row("야간정액", suffix: "원", value: nightFlatFee) }
                    if nightFlatFee > 0 {
                        Picker("야간 시작", selection: $nightStartHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d:00", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        Picker("야간 종료", selection: $nightEndHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(String(format: "%02d:00", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }
            }
            .navigationTitle("타이머 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                }
            }
        }
    }

    private func save() {
        let tariff = ParkingTariff(
            baseFee: baseFee,
            baseMinutes: baseMinutes,
            unitFee: unitFee,
            unitMinutes: unitMinutes,
            maxFee: maxFee == 0 ? nil : maxFee,
            freeMinutes: freeMinutes,
            dailyMaxFee: dailyMaxFee == 0 ? nil : dailyMaxFee,
            nightFlatFee: nightFlatFee == 0 ? nil : nightFlatFee,
            nightStartHour: nightFlatFee > 0 ? nightStartHour : nil,
            nightEndHour: nightFlatFee > 0 ? nightEndHour : nil
        )

        let session = ParkingSession(
            name: name,
            startedAt: Date(),
            tariff: tariff
        )

        onSave(session)
        dismiss()
    }

    private func row(_ title: String, suffix: String, value: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)\(suffix)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    TimerFormView { _ in }
}


