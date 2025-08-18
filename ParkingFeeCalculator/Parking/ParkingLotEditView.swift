//
//  ParkingLotEditView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/13/25.
//

import SwiftUI

struct ParkingLotEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfileVM: UserProfileViewModel

    @State private var name: String = ""
    @State private var address: String = ""
    @State private var hasInitialFee: Bool = false
    @State private var initialFee: Int = ParkingLotDefaults.initialFee
    @State private var initialMinutes: Int = ParkingLotDefaults.initialMinutes
    @State private var additionalFee: Int = ParkingLotDefaults.additionalFee
    @State private var additionalMinutes: Int = ParkingLotDefaults.additionalMinutes
    @State private var hasMaxFee: Bool = false
    @State private var maxFee: Int = ParkingLotDefaults.maxFee
    @State private var freeMinutes: Int = ParkingLotDefaults.freeMinutes
    @State private var hasDailyMaxFee: Bool = false
    @State private var dailyMaxFee: Int = ParkingLotDefaults.dailyMaxFee
    @State private var hasNightRate: Bool = false
    @State private var nightFlatFee: Int = ParkingLotDefaults.nightFlatFee
    @State private var nightStartHour: Int = ParkingLotDefaults.nightStartHour
    @State private var nightEndHour: Int = ParkingLotDefaults.nightEndHour
    @State private var mildDiscountPercentage: Double = ParkingLotDefaults.mildDiscountPercentage
    @State private var severeDiscountPercentage: Double = ParkingLotDefaults.severeDiscountPercentage
    @State private var nationalMeritDiscountPercentage: Double = ParkingLotDefaults.nationalMeritDiscountPercentage
    @State private var exemplaryTaxpayerDiscountPercentage: Double = ParkingLotDefaults.exemplaryTaxpayerDiscountPercentage
    @State private var multiChildDiscountPercentage: Double = ParkingLotDefaults.multiChildDiscountPercentage
    @State private var seniorDiscountPercentage: Double = ParkingLotDefaults.seniorDiscountPercentage
    @State private var hasMildDiscount: Bool = false
    @State private var hasSevereDiscount: Bool = false
    @State private var hasNationalMeritDiscount: Bool = false
    @State private var hasExemplaryTaxpayerDiscount: Bool = false
    @State private var hasMultiChildDiscount: Bool = false
    @State private var hasSeniorDiscount: Bool = false
    
    // 차량 관련 할인 상태
    @State private var hasLightCarDiscount: Bool = false
    @State private var lightCarDiscountPercentage: Double = ParkingLotDefaults.lightCarDiscountPercentage
    @State private var hasNormalCarDiscount: Bool = false
    @State private var normalCarDiscountPercentage: Double = ParkingLotDefaults.normalCarDiscountPercentage
    @State private var hasLargeCarDiscount: Bool = false
    @State private var largeCarDiscountPercentage: Double = ParkingLotDefaults.largeCarDiscountPercentage

    @State private var hasElectricDiscount: Bool = false
    @State private var electricDiscountPercentage: Double = ParkingLotDefaults.electricDiscountPercentage
    @State private var hasHydrogenDiscount: Bool = false
    @State private var hydrogenDiscountPercentage: Double = ParkingLotDefaults.hydrogenDiscountPercentage
    @State private var hasHybridDiscount: Bool = false
    @State private var hybridDiscountPercentage: Double = ParkingLotDefaults.hybridDiscountPercentage

    let parkingLotProfile: ParkingLotProfile?
    let onSave: (ParkingLotProfile) -> Void

    init(parkingLotProfile: ParkingLotProfile? = nil, onSave: @escaping (ParkingLotProfile) -> Void) {
        self.parkingLotProfile = parkingLotProfile
        self.onSave = onSave
        
        // 기존 데이터가 있으면 로드
        if let profile = parkingLotProfile {
            _name = State(initialValue: profile.name)
            _address = State(initialValue: profile.address)
                    _hasInitialFee = State(initialValue: profile.parkingFeeCalculator.initialFee > 0)
        _initialFee = State(initialValue: profile.parkingFeeCalculator.initialFee)
        _initialMinutes = State(initialValue: profile.parkingFeeCalculator.initialMinutes)
        _additionalFee = State(initialValue: profile.parkingFeeCalculator.additionalFee)
        _additionalMinutes = State(initialValue: profile.parkingFeeCalculator.additionalMinutes)
            _hasMaxFee = State(initialValue: profile.parkingFeeCalculator.maxFee != nil)
            _maxFee = State(initialValue: profile.parkingFeeCalculator.maxFee ?? 20000)
            _freeMinutes = State(initialValue: profile.parkingFeeCalculator.freeMinutes)
            _hasDailyMaxFee = State(initialValue: profile.parkingFeeCalculator.dailyMaxFee != nil)
            _dailyMaxFee = State(initialValue: profile.parkingFeeCalculator.dailyMaxFee ?? 20000)
            
            // 야간 요금 설정
            _hasNightRate = State(initialValue: profile.parkingFeeCalculator.hasNightRate)
            _nightFlatFee = State(initialValue: profile.parkingFeeCalculator.nightFlatFee ?? 0)
            _nightStartHour = State(initialValue: profile.parkingFeeCalculator.nightStartHour ?? 22)
            _nightEndHour = State(initialValue: profile.parkingFeeCalculator.nightEndHour ?? 7)
            
            // 기존 할인 시스템에서 데이터 로드
            let discounts = profile.specialConditionDiscounts
            _hasMildDiscount = State(initialValue: discounts.mildDiscountPercentage != nil)
            _mildDiscountPercentage = State(initialValue: discounts.mildDiscountPercentage ?? 0)
            _hasSevereDiscount = State(initialValue: discounts.severeDiscountPercentage != nil)
            _severeDiscountPercentage = State(initialValue: discounts.severeDiscountPercentage ?? 0)
            _hasNationalMeritDiscount = State(initialValue: discounts.nationalMeritDiscountPercentage != nil)
            _nationalMeritDiscountPercentage = State(initialValue: discounts.nationalMeritDiscountPercentage ?? 0)
            _hasExemplaryTaxpayerDiscount = State(initialValue: discounts.exemplaryTaxpayerDiscountPercentage != nil)
            _exemplaryTaxpayerDiscountPercentage = State(initialValue: discounts.exemplaryTaxpayerDiscountPercentage ?? 0)
            _hasMultiChildDiscount = State(initialValue: discounts.multiChildDiscountPercentage != nil)
            _multiChildDiscountPercentage = State(initialValue: discounts.multiChildDiscountPercentage ?? 0)
            _hasSeniorDiscount = State(initialValue: discounts.seniorDiscountPercentage != nil)
            _seniorDiscountPercentage = State(initialValue: discounts.seniorDiscountPercentage ?? 0)
            
            // 차량 관련 할인 설정
            _hasLightCarDiscount = State(initialValue: discounts.lightCarDiscountPercentage != nil)
            _lightCarDiscountPercentage = State(initialValue: discounts.lightCarDiscountPercentage ?? 0)
            _hasNormalCarDiscount = State(initialValue: discounts.normalCarDiscountPercentage != nil)
            _normalCarDiscountPercentage = State(initialValue: discounts.normalCarDiscountPercentage ?? 0)
            _hasLargeCarDiscount = State(initialValue: discounts.largeCarDiscountPercentage != nil)
            _largeCarDiscountPercentage = State(initialValue: discounts.largeCarDiscountPercentage ?? 0)

            _hasElectricDiscount = State(initialValue: discounts.electricDiscountPercentage != nil)
            _electricDiscountPercentage = State(initialValue: discounts.electricDiscountPercentage ?? 0)
            _hasHydrogenDiscount = State(initialValue: discounts.hydrogenDiscountPercentage != nil)
            _hydrogenDiscountPercentage = State(initialValue: discounts.hydrogenDiscountPercentage ?? 0)
            _hasHybridDiscount = State(initialValue: discounts.hybridDiscountPercentage != nil)
            _hybridDiscountPercentage = State(initialValue: discounts.hybridDiscountPercentage ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("주차장 정보") {
                    TextField("이름", text: $name)
                    TextField("주소", text: $address)
                }

                Section("기본 요금") {
                    Toggle("기본 요금 적용", isOn: $hasInitialFee)
                    
                    if hasInitialFee {
                        Stepper(value: $initialFee, in: 0...100_000, step: 100) { row("기본요금", suffix: "원", value: initialFee) }
                        Stepper(value: $initialMinutes, in: 5...180, step: 5) { row("기본시간", suffix: "분", value: initialMinutes) }
                    }
                }
                
                Section("추가 요금") {
                    Stepper(value: $additionalFee, in: 0...20_000, step: 50) { row("추가요금", suffix: "원", value: additionalFee) }
                    Stepper(value: $additionalMinutes, in: 5...240, step: 5) { row("단위시간", suffix: "분", value: additionalMinutes) }
                }
                
                Section("할인 및 제한") {
                    Stepper(value: $freeMinutes, in: 0...60, step: 5) { row("무료시간", suffix: "분", value: freeMinutes) }
                    
                    Toggle("1회 최대요금 적용", isOn: $hasMaxFee)
                    if hasMaxFee {
                        Stepper(value: $maxFee, in: 0...200_000, step: 1000) { row("1회 최대요금", suffix: "원", value: maxFee) }
                    }
                    
                    Toggle("일일 최대요금 적용", isOn: $hasDailyMaxFee)
                    if hasDailyMaxFee {
                        Stepper(value: $dailyMaxFee, in: 0...200_000, step: 1000) { row("일일 최대요금", suffix: "원", value: dailyMaxFee) }
                    }
                }
                
                Section("야간 요금") {
                    Toggle("야간 요금 적용", isOn: $hasNightRate)
                    
                    if hasNightRate {
                        Stepper(value: $nightFlatFee, in: 0...200_000, step: 1000) { row("야간 정액요금", suffix: "원", value: nightFlatFee) }
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
                
                Section("특별 조건 할인") {
                    discountToggle("경증 장애인 할인", isOn: $hasMildDiscount, isApplicable: userProfileVM.driverProfile.isDisabled && userProfileVM.driverProfile.disabilityLevel == .mild)
                        .onChange(of: hasMildDiscount) { newValue in
                            if newValue && mildDiscountPercentage == 0 {
                                mildDiscountPercentage = 80
                            }
                        }
                    if hasMildDiscount {
                        Stepper(value: $mildDiscountPercentage, in: 0...100, step: 5) {
                            row("경증 할인율", suffix: "%", value: Int(mildDiscountPercentage))
                        }
                    }
                    
                    discountToggle("중증 장애인 할인", isOn: $hasSevereDiscount, isApplicable: userProfileVM.driverProfile.isDisabled && userProfileVM.driverProfile.disabilityLevel == .severe)
                        .onChange(of: hasSevereDiscount) { newValue in
                            if newValue && severeDiscountPercentage == 0 {
                                severeDiscountPercentage = 80
                            }
                        }
                    if hasSevereDiscount {
                        Stepper(value: $severeDiscountPercentage, in: 0...100, step: 5) {
                            row("중증 할인율", suffix: "%", value: Int(severeDiscountPercentage))
                        }
                    }
                    
                    discountToggle("국가유공자 할인", isOn: $hasNationalMeritDiscount, isApplicable: userProfileVM.driverProfile.isNationalMerit)
                        .onChange(of: hasNationalMeritDiscount) { newValue in
                            if newValue && nationalMeritDiscountPercentage == 0 {
                                nationalMeritDiscountPercentage = 80
                            }
                        }
                    if hasNationalMeritDiscount {
                        Stepper(value: $nationalMeritDiscountPercentage, in: 0...100, step: 5) {
                            row("국가유공자 할인율", suffix: "%", value: Int(nationalMeritDiscountPercentage))
                        }
                    }
                    
                    discountToggle("모범납세자 할인", isOn: $hasExemplaryTaxpayerDiscount, isApplicable: userProfileVM.driverProfile.isExemplaryTaxpayer)
                        .onChange(of: hasExemplaryTaxpayerDiscount) { newValue in
                            if newValue && exemplaryTaxpayerDiscountPercentage == 0 {
                                exemplaryTaxpayerDiscountPercentage = 100
                            }
                        }
                    if hasExemplaryTaxpayerDiscount {
                        Stepper(value: $exemplaryTaxpayerDiscountPercentage, in: 0...100, step: 5) {
                            row("모범납세자 할인율", suffix: "%", value: Int(exemplaryTaxpayerDiscountPercentage))
                        }
                    }
                    
                    discountToggle("다자녀 할인", isOn: $hasMultiChildDiscount, isApplicable: userProfileVM.driverProfile.isMultiChild)
                        .onChange(of: hasMultiChildDiscount) { newValue in
                            if newValue && multiChildDiscountPercentage == 0 {
                                multiChildDiscountPercentage = 50
                            }
                        }
                    if hasMultiChildDiscount {
                        Stepper(value: $multiChildDiscountPercentage, in: 0...100, step: 5) {
                            row("다자녀 할인율", suffix: "%", value: Int(multiChildDiscountPercentage))
                        }
                    }
                    
                    discountToggle("고령자 할인", isOn: $hasSeniorDiscount, isApplicable: userProfileVM.driverProfile.isSenior)
                        .onChange(of: hasSeniorDiscount) { newValue in
                            if newValue && seniorDiscountPercentage == 0 {
                                seniorDiscountPercentage = 50
                            }
                        }
                    if hasSeniorDiscount {
                        Stepper(value: $seniorDiscountPercentage, in: 0...100, step: 5) {
                            row("고령자 할인율", suffix: "%", value: Int(seniorDiscountPercentage))
                        }
                    }
                }
                
                Section("차량 크기별 할인") {
                    discountToggle("경차 할인", isOn: $hasLightCarDiscount, isApplicable: userProfileVM.vehicleProfile.vehicleSize == .light)
                        .onChange(of: hasLightCarDiscount) { newValue in
                            if newValue && lightCarDiscountPercentage == 0 {
                                lightCarDiscountPercentage = 50
                            }
                        }
                    if hasLightCarDiscount {
                        Stepper(value: $lightCarDiscountPercentage, in: 0...100, step: 5) {
                            row("경차 할인율", suffix: "%", value: Int(lightCarDiscountPercentage))
                        }
                    }
                    
                    discountToggle("대형차 할증", isOn: $hasLargeCarDiscount, isApplicable: userProfileVM.vehicleProfile.vehicleSize == .large)
                        .onChange(of: hasLargeCarDiscount) { newValue in
                            if newValue && largeCarDiscountPercentage == 0 {
                                largeCarDiscountPercentage = 0
                            }
                        }
                    if hasLargeCarDiscount {
                        Stepper(value: $largeCarDiscountPercentage, in: 100...300, step: 10) {
                            row("대형차 할증", suffix: "%", value: Int(largeCarDiscountPercentage))
                        }
                    }
                }
                
                Section("친환경 차량 할인") {
                    discountToggle("전기차 할인", isOn: $hasElectricDiscount, isApplicable: userProfileVM.vehicleProfile.isElectric)
                        .onChange(of: hasElectricDiscount) { newValue in
                            if newValue && electricDiscountPercentage == 0 {
                                electricDiscountPercentage = 50
                            }
                        }
                    if hasElectricDiscount {
                        Stepper(value: $electricDiscountPercentage, in: 0...100, step: 5) {
                            row("전기차 할인율", suffix: "%", value: Int(electricDiscountPercentage))
                        }
                    }
                    
                    discountToggle("수소차 할인", isOn: $hasHydrogenDiscount, isApplicable: userProfileVM.vehicleProfile.isHydrogen)
                        .onChange(of: hasHydrogenDiscount) { newValue in
                            if newValue && hydrogenDiscountPercentage == 0 {
                                hydrogenDiscountPercentage = 50
                            }
                        }
                    if hasHydrogenDiscount {
                        Stepper(value: $hydrogenDiscountPercentage, in: 0...100, step: 5) {
                            row("수소차 할인율", suffix: "%", value: Int(hydrogenDiscountPercentage))
                        }
                    }
                    
                    discountToggle("하이브리드 차량 할인", isOn: $hasHybridDiscount, isApplicable: userProfileVM.vehicleProfile.isHybrid)
                        .onChange(of: hasHybridDiscount) { newValue in
                            if newValue && hybridDiscountPercentage == 0 {
                                hybridDiscountPercentage = 50
                            }
                        }
                    if hasHybridDiscount {
                        Stepper(value: $hybridDiscountPercentage, in: 0...100, step: 5) {
                            row("하이브리드 할인율", suffix: "%", value: Int(hybridDiscountPercentage))
                        }
                    }
                }
            }
            .navigationTitle(parkingLotProfile != nil ? "주차장 수정" : "주차장 추가")
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
        let parkingFeeCalculator = ParkingFeeCalculator(
            initialFee: hasInitialFee ? initialFee : 0,
            initialMinutes: hasInitialFee ? initialMinutes : 0,
            additionalFee: additionalFee,
            additionalMinutes: additionalMinutes,
            maxFee: hasMaxFee ? maxFee : nil,
            freeMinutes: freeMinutes,
            dailyMaxFee: hasDailyMaxFee ? dailyMaxFee : nil,
            nightFlatFee: hasNightRate ? (nightFlatFee == 0 ? nil : nightFlatFee) : nil,
            nightStartHour: hasNightRate ? nightStartHour : nil,
            nightEndHour: hasNightRate ? nightEndHour : nil
        )

        let specialConditionDiscounts = SpecialConditionDiscounts(
            mildDiscountPercentage: hasMildDiscount ? mildDiscountPercentage : nil,
            severeDiscountPercentage: hasSevereDiscount ? severeDiscountPercentage : nil,
            nationalMeritDiscountPercentage: hasNationalMeritDiscount ? nationalMeritDiscountPercentage : nil,
            exemplaryTaxpayerDiscountPercentage: hasExemplaryTaxpayerDiscount ? exemplaryTaxpayerDiscountPercentage : nil,
            multiChildDiscountPercentage: hasMultiChildDiscount ? multiChildDiscountPercentage : nil,
            seniorDiscountPercentage: hasSeniorDiscount ? seniorDiscountPercentage : nil,
            lightCarDiscountPercentage: hasLightCarDiscount ? lightCarDiscountPercentage : nil,
            normalCarDiscountPercentage: hasNormalCarDiscount ? normalCarDiscountPercentage : nil,
            largeCarDiscountPercentage: hasLargeCarDiscount ? largeCarDiscountPercentage : nil,

            electricDiscountPercentage: hasElectricDiscount ? electricDiscountPercentage : nil,
            hydrogenDiscountPercentage: hasHydrogenDiscount ? hydrogenDiscountPercentage : nil,
            hybridDiscountPercentage: hasHybridDiscount ? hybridDiscountPercentage : nil
        )
        
        // 기존 주차장 정보가 있으면 기존 ID와 생성일을 유지하고, 없으면 새로운 정보로 생성
        let updatedParkingLotProfile: ParkingLotProfile
        if let existingProfile = parkingLotProfile {
            // 기존 프로필의 ID와 생성일을 유지하면서 업데이트
            updatedParkingLotProfile = ParkingLotProfile(
                id: existingProfile.id,
                name: name.isEmpty ? "새 주차장" : name,
                address: address.isEmpty ? "주소 미입력" : address,
                parkingFeeCalculator: parkingFeeCalculator,
                specialConditionDiscounts: specialConditionDiscounts,
                createdAt: existingProfile.createdAt,
                updatedAt: Date()
            )
        } else {
            // 새로운 주차장 생성
            updatedParkingLotProfile = ParkingLotProfile(
                name: name.isEmpty ? "새 주차장" : name,
                address: address.isEmpty ? "주소 미입력" : address,
                parkingFeeCalculator: parkingFeeCalculator,
                specialConditionDiscounts: specialConditionDiscounts
            )
        }

        onSave(updatedParkingLotProfile)
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
    
    private func discountToggle(_ title: String, isOn: Binding<Bool>, isApplicable: Bool) -> some View {
        Toggle(isOn: isOn) {
            HStack {
                Text(title)
                if isApplicable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
        }
    }
}

#Preview {
    ParkingLotEditView { _ in }
}


