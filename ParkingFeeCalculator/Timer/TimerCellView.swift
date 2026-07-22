//
//  TimerCellView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import SwiftUI
import WidgetKit
// import ParkingFeeCore // 임시 제거

struct TimerCellView: View {
    @Binding var isParkingActive: Bool
    @State private var parkingStartTime = Date()
    @State private var currentTime = Date()
    @State private var currentFee = 0
    @State private var displayTimer: Timer? // 경과 시간 표시용 타이머 (1초마다)
    @State private var showingStopConfirmation = false
    @State private var additionalFreeMinutes: Int = 0
    @StateObject private var liveActivityController = ParkingLiveActivityController()
    
    // 실제 주차장 정보 (외부에서 주입받음)
    let parkingLotProfile: ParkingLotProfile?
    
    
    // 사용자 프로필 정보
    @EnvironmentObject var userProfileVM: UserProfileViewModel
    
    init(isParkingActive: Binding<Bool>, parkingLotProfile: ParkingLotProfile? = nil) {
        self._isParkingActive = isParkingActive
        self.parkingLotProfile = parkingLotProfile
    }
    
    private var currentParkingLot: ParkingLotProfile? {
        return parkingLotProfile
    }
    
    // 실제 사용자 차량 정보 사용
    private var currentVehicle: VehicleProfile {
        return userProfileVM.vehicleProfile
    }
    
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
                                    Text(formatKoreanDateTime(parkingStartTime))
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
                                    Text("기본요금: \(parkingLot.parkingFeeCalculator.initialFee)원")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("추가요금: \(parkingLot.parkingFeeCalculator.additionalFee)원/\(parkingLot.parkingFeeCalculator.additionalMinutes)분")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    // 할인 정보 표시 (새로운 로직)
                                    if let discountInfo = getDiscountInfoWithHighlighting() {
                                        Text(discountInfo)
                                            .font(.caption2)
                                    }
                                }
                            }
                            
                            // 추가 무료시간 Stepper
                            VStack(spacing: 8) {
                                HStack {
                                    Text("추가 무료시간")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(additionalFreeMinutes)분")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .fontWeight(.medium)
                                    Stepper(
                                        value: $additionalFreeMinutes,
                                        in: 0...300,
                                        step: 30
                                    ) {
                                        EmptyView()
                                    }
                                    .onChange(of: additionalFreeMinutes) { _, newValue in
                                        // 세션 매니저에 추가 무료시간 업데이트
                                        ParkingSessionManager.shared.updateAdditionalFreeMinutes(newValue)
                                        // 주차비 재계산 (UI 표시용)
                                        updateDisplayFee()
                                        // Live Activity도 즉시 업데이트 (설정 변경)
                                        liveActivityController.update(
                                            currentFee: currentFee,
                                            startedAt: parkingStartTime
                                        )
                                    }
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
                                    Text("\(parkingLot.parkingFeeCalculator.initialFee)원/\(parkingLot.parkingFeeCalculator.initialMinutes)분")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("추가 요금")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(parkingLot.parkingFeeCalculator.additionalFee)원/\(parkingLot.parkingFeeCalculator.additionalMinutes)분")
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
                                    Text("주차 시작 후 실시간 계산")
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
                                    
                                    // 할인 정보 표시 (새로운 로직)
                                    if let discountInfo = getDiscountInfoWithHighlighting() {
                                        Text(discountInfo)
                                            .font(.caption2)
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
                            .buttonStyle(.plain)
                            .allowsHitTesting(true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    } else {
                        // 주차 시작 전 안내 메시지 (개선된 가이드 텍스트)
                        VStack(spacing: 6) {
                            Text("아직 주차를 시작하지 않았어요")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Text("주차장 상세 화면에서 ‘주차 시작’을 누르면\n타이머와 실시간 요금이 표시됩니다.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            } else {
                // 주차장이 선택되지 않은 경우 - 안내 메시지 표시
                VStack(spacing: 20) {
                    Image(systemName: "building.2")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("주차장을 선택해주세요")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("주차장 목록에서 주차장을 선택하거나\n새로운 주차장을 추가해주세요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: isParkingActive) { _, newValue in
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
    
    // MARK: - Helper Methods
    private func formatKoreanDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일 a h:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    private func startParking() {
        guard let parkingLot = currentParkingLot else {
            print("❌ 주차장 정보가 없어서 주차를 시작할 수 없습니다.")
            return
        }
        
        parkingStartTime = Date()
        currentTime = Date()
        
        // ParkingFeeCore를 사용한 새 세션 시작
        let session = SharedParkingSession(
            startTime: parkingStartTime,
            parkingLot: parkingLot,
            vehicle: currentVehicle,
            driver: userProfileVM.driverProfile,
            additionalFreeMinutes: additionalFreeMinutes
        )
        
        // 세션 매니저에 등록
        ParkingSessionManager.shared.startSession(session)
        
        // 현재 주차비 계산
        currentFee = session.currentFee
        
        // Live Activity 시작
        print("🚀 Live Activity 시작 시도...")
        print("주차장: \(parkingLot.name)")
        print("시작시간: \(parkingStartTime)")
        print("현재요금: \(currentFee)")
        
        liveActivityController.start(
            startedAt: parkingStartTime,
            lotName: parkingLot.name,
            currentFee: currentFee,
            discountInfo: session.discountInfo
        )
    }
    
    private func stopParking() {
        isParkingActive = false
        stopTimer()
        
        // ParkingFeeCore를 사용한 세션 종료
        ParkingSessionManager.shared.endSession()
        
        // Live Activity 종료
        liveActivityController.end()
        
        print("🛑 주차 세션 종료 완료")
    }
    
    private func startTimer() {
        // 경과 시간 표시용 타이머 (1초마다)
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
        
        // 주차비 계산은 Live Activity 스케줄러가 담당
        // UI 표시용으로만 현재 요금 업데이트 (매 10초마다)
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            if isParkingActive {
                updateDisplayFee()
            }
        }
        
        // 주차 시작 시 즉시 첫 번째 계산 실행
        if isParkingActive {
            DispatchQueue.main.async {
                updateDisplayFee()
            }
        }
    }
    
    private func stopTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }
    
    // MARK: - UI 표시용 요금 업데이트 (ParkingFeeCore 사용)
    private func updateDisplayFee() {
        guard let session = ParkingSessionManager.shared.currentSession() else {
            print("❌ 활성 세션이 없습니다.")
            return
        }
        
        // ParkingFeeCore로 현재 요금 계산
        let result = FeeCalculationService.shared.calculateFee(for: session)
        
        DispatchQueue.main.async {
            self.currentFee = result.finalFee
        }
    }
    
    // MARK: - 레거시 지원: calculateCurrentFee (내부적으로 updateDisplayFee 호출)
    private func calculateCurrentFee() {
        updateDisplayFee()
        
    }
    
    // MARK: - 위젯 업데이트 (ParkingSessionManager가 자동 처리)
    private func requestWidgetUpdate() {
        // ParkingSessionManager가 자동으로 위젯을 업데이트하므로
        // 여기서는 명시적 요청만 수행
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func getDiscountInfo() -> String? {
        // 현재 세션에서 할인 정보 가져오기
        return ParkingSessionManager.shared.currentDiscountInfo
    }
    
    private func getDiscountInfoWithHighlighting() -> AttributedString? {
        guard let session = ParkingSessionManager.shared.currentSession() else { return nil }
        
        // FeeCalculationService를 사용해 할인 정보 계산
        let result = FeeCalculationService.shared.calculateFee(for: session)
        
        guard !result.applicableDiscounts.isEmpty else { return nil }
        
        var attributedString = AttributedString()
        
        if result.applicableDiscounts.count == 1 {
            // 할인이 하나만 있는 경우
            let discount = result.applicableDiscounts[0]
            attributedString += AttributedString("적용된 할인: ")
            attributedString += AttributedString("\(discount.name) \(Int(discount.percentage))%")
        } else {
            // 여러 할인이 있는 경우
            attributedString += AttributedString("적용 가능: ")
            
            // 가장 높은 할인율 찾기
            let bestDiscount = result.applicableDiscounts.max { $0.percentage < $1.percentage }
            
            for (index, discount) in result.applicableDiscounts.enumerated() {
                if index > 0 {
                    attributedString += AttributedString(", ")
                }
                
                var discountText = AttributedString("\(discount.name) \(Int(discount.percentage))%")
                
                // 가장 높은 할인율인 경우 빨간색 볼드체로 표시
                if discount.percentage == bestDiscount?.percentage {
                    discountText.foregroundColor = .red
                    discountText.font = .boldSystemFont(ofSize: UIFont.systemFontSize)
                }
                
                attributedString += discountText
            }
        }
        
        return attributedString
    }
}

#Preview {
    TimerCellView(isParkingActive: .constant(false))
        .environmentObject(UserProfileViewModel())
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
}
