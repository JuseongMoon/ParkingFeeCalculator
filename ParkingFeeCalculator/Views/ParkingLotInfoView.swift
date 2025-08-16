//
//  ParkingLotInfoView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import SwiftUI

struct ParkingLotInfoView: View {
    let parkingLotProfile: ParkingLotProfile
    @Environment(\.dismiss) private var dismiss
    @State private var isStartingParking: Bool = false
    @State private var isPresentingEditForm: Bool = false
    @Binding var isParkingActive: Bool
    let onUpdate: ((ParkingLotProfile) -> Void)?
    let onParkingStart: ((ParkingLotProfile) -> Void)?
    
    init(parkingLotProfile: ParkingLotProfile, isParkingActive: Binding<Bool>, onUpdate: ((ParkingLotProfile) -> Void)? = nil, onParkingStart: ((ParkingLotProfile) -> Void)? = nil) {
        self.parkingLotProfile = parkingLotProfile
        self._isParkingActive = isParkingActive
        self.onUpdate = onUpdate
        self.onParkingStart = onParkingStart
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 주차장 기본 정보 섹션
                    infoSection(
                        title: "주차장 정보",
                        icon: "building.2.fill",
                        color: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            infoRow(title: "주차장명", value: parkingLotProfile.displayName)
                            infoRow(title: "주소", value: parkingLotProfile.address)
                            infoRow(title: "운영 상태", value: parkingLotProfile.isOpen ? "운영 중" : "운영 종료")
                        }
                    }
                    
                    // 요금 정보 섹션
                    infoSection(
                        title: "요금 정보",
                        icon: "creditcard.fill",
                        color: .green
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            infoRow(title: "기본 요금", value: "\(parkingLotProfile.parkingFeeCalculator.baseFee)원/\(parkingLotProfile.parkingFeeCalculator.baseMinutes)분")
                            if parkingLotProfile.parkingFeeCalculator.unitFee > 0 {
                                infoRow(title: "추가 요금", value: "\(parkingLotProfile.parkingFeeCalculator.unitFee)원/\(parkingLotProfile.parkingFeeCalculator.unitMinutes)분")
                            }
                            if let maxFee = parkingLotProfile.parkingFeeCalculator.maxFee {
                                infoRow(title: "최대 요금", value: "\(maxFee)원")
                            }
                            if let dailyMaxFee = parkingLotProfile.parkingFeeCalculator.dailyMaxFee {
                                infoRow(title: "일일 최대", value: "\(dailyMaxFee)원")
                            }
                            if parkingLotProfile.parkingFeeCalculator.freeMinutes > 0 {
                                infoRow(title: "무료 시간", value: "\(parkingLotProfile.parkingFeeCalculator.freeMinutes)분")
                            }
                        }
                    }
                    
                    // 야간 요금 정보 (있는 경우)
                    if parkingLotProfile.parkingFeeCalculator.hasNightRate {
                        infoSection(
                            title: "야간 요금",
                            icon: "moon.fill",
                            color: .purple
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                if let nightFee = parkingLotProfile.parkingFeeCalculator.nightFlatFee {
                                    infoRow(title: "야간 요금", value: "\(nightFee)원")
                                }
                                if let startHour = parkingLotProfile.parkingFeeCalculator.nightStartHour,
                                   let endHour = parkingLotProfile.parkingFeeCalculator.nightEndHour {
                                    infoRow(title: "야간 시간", value: "\(startHour)시 ~ \(endHour)시")
                                }
                            }
                        }
                    }
                    
                    // 차량별 요금 정보
                    if !parkingLotProfile.parkingFeeCalculator.vehicleSizeMultipliers.isEmpty {
                        infoSection(
                            title: "차량별 요금",
                            icon: "car.fill",
                            color: .orange
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(VehicleSize.allCases, id: \.self) { vehicleSize in
                                    let multiplier = parkingLotProfile.parkingFeeCalculator.getVehicleMultiplier(for: vehicleSize)
                                    if multiplier != 1.0 {
                                        infoRow(title: vehicleSize.displayName, value: "\(Int(multiplier * 100))% 요금")
                                    }
                                }
                            }
                        }
                    }
                    
                    // 할인 정책 정보
                    if parkingLotProfile.specialConditionDiscounts.hasAnyDiscount {
                        infoSection(
                            title: "할인 정책",
                            icon: "percent",
                            color: .red
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                infoRow(title: "적용 가능", value: parkingLotProfile.specialConditionDiscounts.displayDescription)
                            }
                        }
                    }
                    
                    // 주차 시작 버튼
                    if parkingLotProfile.isOpen && !isParkingActive {
                        VStack(spacing: 16) {
                            Button(action: {
                                isStartingParking = true
                                // 주차 시작 로직
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isParkingActive = true
                                    isStartingParking = false
                                    // 현재 주차장 정보를 부모 뷰에 전달
                                    onParkingStart?(parkingLotProfile)
                                    // 화면 닫기
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("주차 시작")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            .disabled(isStartingParking)
                            
                            if isStartingParking {
                                ProgressView("주차 시작 중...")
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .padding()
            }
            .navigationTitle("주차장 정보")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if onUpdate != nil {
                        Button("수정") {
                            isPresentingEditForm = true
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isPresentingEditForm) {
                ParkingLotEditView(parkingLotProfile: parkingLotProfile) { updatedProfile in
                    onUpdate?(updatedProfile)
                }
            }
        }
    }
    
    @ViewBuilder
    private func infoSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 0) {
                content()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    let sampleParkingLot = ParkingLotProfile(
        name: "테스트 주차장",
        address: "서울시 강남구 테헤란로 123",
        parkingFeeCalculator: ParkingFeeCalculator(
            baseFee: 1000,
            baseMinutes: 30,
            unitFee: 500,
            unitMinutes: 10,
            maxFee: 10000,
            freeMinutes: 10,
            dailyMaxFee: 20000,
            nightFlatFee: 5000,
            nightStartHour: 22,
            nightEndHour: 6
        ),
        specialConditionDiscounts: SpecialConditionDiscounts(
            mildDiscountPercentage: 20.0,
            severeDiscountPercentage: 50.0,
            nationalMeritDiscountPercentage: 30.0
        )
    )
    
    ParkingLotInfoView(
        parkingLotProfile: sampleParkingLot,
        isParkingActive: .constant(false),
        onUpdate: { _ in },
        onParkingStart: { _ in }
    )
}
