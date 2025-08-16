//
//  TimerCellView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import SwiftUI

struct TimerCellView: View {
    @Binding var isParkingActive: Bool
    @State private var parkingStartTime = Date()
    @State private var currentTime = Date()
    @State private var currentFee = 0
    @State private var timer: Timer?
    @State private var showingStopConfirmation = false
    
    // 실제 주차장 정보 (외부에서 주입받음)
    let parkingLotProfile: ParkingLotProfile?
    
    init(isParkingActive: Binding<Bool>, parkingLotProfile: ParkingLotProfile? = nil) {
        self._isParkingActive = isParkingActive
        self.parkingLotProfile = parkingLotProfile
    }
    
    // 기본 샘플 데이터 (parkingLotProfile이 nil일 때 사용)
    private var sampleParkingLot: ParkingLotProfile {
        ParkingLotProfile(
            name: "샘플 주차장",
            address: "서울시 강남구",
            parkingFeeCalculator: ParkingFeeCalculator(
                baseFee: 1000,
                baseMinutes: 60,
                unitFee: 500,
                unitMinutes: 30,
                maxFee: 10000
            )
        )
    }
    
    private var currentParkingLot: ParkingLotProfile? {
        return parkingLotProfile
    }
    
    private let sampleVehicle = VehicleProfile(vehicleSize: .normal)
    
    var body: some View {
        VStack(spacing: 16) {
            if let parkingLot = currentParkingLot {
                // 주차장이 선택된 경우 - 전체 UI 표시
                VStack(spacing: 16) {
                    // 주차장 정보 헤더
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(parkingLot.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(parkingLot.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // 주차 상태 표시
                        HStack(spacing: 8) {
                            Circle()
                                .fill(isParkingActive ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            
                            Text(isParkingActive ? "주차중" : "대기중")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    if isParkingActive {
                        // 주차 중일 때 - 실시간 정보 표시
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("시작 시간")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(parkingStartTime, style: .time)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("경과 시간")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(elapsedTimeString)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Divider()
                            
                            // 실시간 주차비 표시
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("현재 주차비")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(currentFee)원")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                // 주차비 계산 상세 정보
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("기본요금: \(parkingLot.parkingFeeCalculator.baseFee)원")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("추가요금: \(parkingLot.parkingFeeCalculator.unitFee)원/\(parkingLot.parkingFeeCalculator.unitMinutes)분")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        // 주차 시작 전 - 요금 정보 표시
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("기본 요금")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(parkingLot.parkingFeeCalculator.baseFee)원/\(parkingLot.parkingFeeCalculator.baseMinutes)분")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("추가 요금")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(parkingLot.parkingFeeCalculator.unitFee)원/\(parkingLot.parkingFeeCalculator.unitMinutes)분")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Divider()
                            
                            // 예상 주차비 정보
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("예상 주차비")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("시작 후 계산")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // 주차비 계산 상세 정보
                                VStack(alignment: .trailing, spacing: 2) {
                                    if let maxFee = parkingLot.parkingFeeCalculator.maxFee {
                                        Text("최대요금: \(maxFee)원")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    if parkingLot.parkingFeeCalculator.freeMinutes > 0 {
                                        Text("무료시간: \(parkingLot.parkingFeeCalculator.freeMinutes)분")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // 주차 종료 버튼 (주차 중일 때만 표시)
                    if isParkingActive {
                        HStack(spacing: 12) {
                            Button(action: { showingStopConfirmation = true }) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text("주차 종료")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    } else {
                        // 주차 시작 전 안내 메시지
                        VStack(spacing: 8) {
                            Text("주차장 정보에서 주차 시작 버튼을 눌러주세요")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            } else {
                // 주차장이 선택되지 않은 경우 - 깔끔한 안내 메시지만 표시
                VStack(spacing: 20) {
                    Image(systemName: "building.2")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("주차장을 선택해주세요")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("아래 주차장 목록에서 주차장을 선택하고\n주차 시작 버튼을 눌러주세요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: isParkingActive) { newValue in
            if newValue {
                startParking()
            }
        }
        .alert("주차 종료", isPresented: $showingStopConfirmation) {
            Button("취소", role: .cancel) { }
            Button("주차 종료", role: .destructive) {
                stopParking()
            }
        } message: {
            Text("정말로 주차를 종료하시겠습니까?\n현재 주차비는 \(currentFee)원입니다.")
        }
    }
    
    // MARK: - Computed Properties
    private var elapsedTimeString: String {
        let elapsed = currentTime.timeIntervalSince(parkingStartTime)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Actions
    private func startParking() {
        parkingStartTime = Date()
        currentTime = Date()
        calculateCurrentFee()
    }
    
    private func stopParking() {
        isParkingActive = false
        stopTimer()
        // 여기서 주차 세션을 저장하는 로직 추가
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
            if isParkingActive {
                calculateCurrentFee()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func calculateCurrentFee() {
        guard let parkingLot = currentParkingLot else { return }
        
        let elapsed = currentTime.timeIntervalSince(parkingStartTime)
        let elapsedMinutes = elapsed / 60.0
        
        let calculator = parkingLot.parkingFeeCalculator
        
        // 무료 시간 적용
        if elapsedMinutes <= Double(calculator.freeMinutes) {
            currentFee = 0
            return
        }
        
        // 기본 요금 계산
        var fee = calculator.baseFee
        
        // 추가 요금 계산
        if elapsedMinutes > Double(calculator.baseMinutes) {
            let additionalMinutes = elapsedMinutes - Double(calculator.baseMinutes)
            let additionalUnits = Int(ceil(additionalMinutes / Double(calculator.unitMinutes)))
            fee += additionalUnits * calculator.unitFee
        }
        
        // 최대 요금 적용
        if let maxFee = calculator.maxFee {
            fee = min(fee, maxFee)
        }
        
        currentFee = fee
    }
}

#Preview {
    TimerCellView(isParkingActive: .constant(false))
        .padding()
        .background(Color(.systemGroupedBackground))
}

