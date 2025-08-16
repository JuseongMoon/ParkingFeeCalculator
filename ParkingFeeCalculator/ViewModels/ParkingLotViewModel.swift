//
//  ParkingLotViewModel.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import Foundation
import Combine

@MainActor
class ParkingLotViewModel: ObservableObject {
    @Published var parkingLots: [ParkingLotProfile] = []
    @Published var selectedParkingLot: ParkingLotProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadParkingLots()
    }
    
    // MARK: - Parking Lot Management
    func loadParkingLots() {
        isLoading = true
        
        // TODO: UserDefaults 또는 Core Data에서 로드
        // 임시로 샘플 데이터 사용
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.parkingLots = self.createSampleParkingLots()
            self.isLoading = false
        }
    }
    
    func addParkingLot(_ parkingLot: ParkingLotProfile) {
        parkingLots.append(parkingLot)
        saveParkingLots()
    }
    
    func updateParkingLot(_ parkingLot: ParkingLotProfile) {
        if let index = parkingLots.firstIndex(where: { $0.id == parkingLot.id }) {
            parkingLots[index] = parkingLot
            saveParkingLots()
        }
    }
    
    func deleteParkingLot(at offsets: IndexSet) {
        parkingLots.remove(atOffsets: offsets)
        saveParkingLots()
    }
    
    func selectParkingLot(_ parkingLot: ParkingLotProfile) {
        selectedParkingLot = parkingLot
    }
    
    // MARK: - Fee Calculation
    func calculateFee(
        for parkingLot: ParkingLotProfile,
        duration: TimeInterval,
        userProfileVM: UserProfileViewModel
    ) -> Int {
        let driverProfile = userProfileVM.getCurrentDriverProfile()
        let vehicleProfile = userProfileVM.getCurrentVehicleProfile()
        
        let calculator = parkingLot.parkingFeeCalculator
        let baseFee = calculator.baseFee
        let baseMinutes = calculator.baseMinutes
        let unitFee = calculator.unitFee
        let unitMinutes = calculator.unitMinutes
        
        // 무료 시간 체크
        if duration <= TimeInterval(calculator.freeMinutes * 60) {
            return 0
        }
        
        // 기본 시간 이후 계산
        let chargeableDuration = duration - TimeInterval(calculator.freeMinutes * 60)
        let chargeableMinutes = Int(chargeableDuration / 60)
        
        if chargeableMinutes <= baseMinutes {
            return baseFee
        }
        
        // 추가 시간 계산
        let additionalMinutes = chargeableMinutes - baseMinutes
        let additionalUnits = Int(ceil(Double(additionalMinutes) / Double(unitMinutes)))
        let additionalFee = additionalUnits * unitFee
        
        var totalFee = baseFee + additionalFee
        
        // 차량 크기별 배수 적용
        let vehicleMultiplier = calculator.getVehicleMultiplier(for: vehicleProfile.vehicleSize)
        totalFee = Int(Double(totalFee) * vehicleMultiplier)
        
        // 최대 요금 제한 (할인 적용 전)
        if let maxFee = calculator.maxFee {
            totalFee = min(totalFee, maxFee)
        }
        
        // 특별 조건 할인 적용 (최종 금액에 대한 퍼센테이지 할인)
        applySpecialConditionDiscounts(
            totalFee: &totalFee,
            driverProfile: driverProfile,
            vehicleProfile: vehicleProfile,
            parkingLotProfile: parkingLot
        )
        
        return totalFee
    }
    
    private func applySpecialDiscounts(
        totalFee: Int,
        calculator: ParkingFeeCalculator,
        driverProfile: DriverProfile,
        vehicleProfile: VehicleProfile,
        parkingLotProfile: ParkingLotProfile
    ) -> Int {
        var discountedFee = totalFee
        
        for discount in calculator.specialDiscounts where discount.isActive {
            var shouldApply = false
            
            for condition in discount.applicableConditions {
                switch condition {
                case .disabledDriver:
                    shouldApply = driverProfile.isDisabled
                case .mildDisabledDriver:
                    shouldApply = driverProfile.isDisabled && driverProfile.disabilityLevel == .mild
                case .severeDisabledDriver:
                    shouldApply = driverProfile.isDisabled && driverProfile.disabilityLevel == .severe
                case .nationalMerit:
                    shouldApply = driverProfile.isNationalMerit
                case .exemplaryTaxpayer:
                    shouldApply = driverProfile.isExemplaryTaxpayer
                case .multiChild:
                    shouldApply = driverProfile.isMultiChild
                case .senior:
                    shouldApply = driverProfile.isSenior
                case .specificVehicleSize(let size):
                    shouldApply = vehicleProfile.vehicleSize == size
                default:
                    break
                }
                
                if shouldApply { break }
            }
            
            if shouldApply {
                if let discountAmount = discount.discountAmount {
                    discountedFee = max(0, discountedFee - discountAmount)
                } else {
                    discountedFee = Int(Double(discountedFee) * (1.0 - discount.discountPercentage / 100.0))
                }
            }
        }
        
        // 특별 조건 할인 적용 (주차장별 할인율 사용)
        applySpecialConditionDiscounts(
            totalFee: &discountedFee,
            driverProfile: driverProfile,
            vehicleProfile: vehicleProfile,
            parkingLotProfile: parkingLotProfile
        )
        
        return discountedFee
    }
    
    private func applySpecialConditionDiscounts(
        totalFee: inout Int,
        driverProfile: DriverProfile,
        vehicleProfile: VehicleProfile,
        parkingLotProfile: ParkingLotProfile
    ) {
        let originalFee = totalFee
        var appliedDiscounts: [String] = []
        // 장애인 할인
        if driverProfile.isDisabled, let level = driverProfile.disabilityLevel {
            let condition: SpecialCondition = (level == .mild) ? .mildDisabled : .severeDisabled
            if let discountPercentage = parkingLotProfile.specialConditionDiscounts.getDiscountPercentage(for: condition) {
                totalFee = Int(Double(totalFee) * (1.0 - discountPercentage / 100.0))
            }
        }
        
        // 국가유공자 할인
        if driverProfile.isNationalMerit {
            if let discountPercentage = parkingLotProfile.specialConditionDiscounts.getDiscountPercentage(for: .nationalMerit) {
                totalFee = Int(Double(totalFee) * (1.0 - discountPercentage / 100.0))
            }
        }
        
        // 모범납세자 할인
        if driverProfile.isExemplaryTaxpayer {
            if let discountPercentage = parkingLotProfile.specialConditionDiscounts.getDiscountPercentage(for: .exemplaryTaxpayer) {
                totalFee = Int(Double(totalFee) * (1.0 - discountPercentage / 100.0))
            }
        }
        
        // 다자녀 할인
        if driverProfile.isMultiChild {
            if let discountPercentage = parkingLotProfile.specialConditionDiscounts.getDiscountPercentage(for: .multiChild) {
                totalFee = Int(Double(totalFee) * (1.0 - discountPercentage / 100.0))
            }
        }
        
        // 고령자 할인
        if driverProfile.isSenior {
            if let discountPercentage = parkingLotProfile.specialConditionDiscounts.getDiscountPercentage(for: .senior) {
                totalFee = Int(Double(totalFee) * (1.0 - discountPercentage / 100.0))
            }
        }
        
        // 차량 크기별 할인
        if let discountPercentage = parkingLotProfile.specialConditionDiscounts.getDiscountPercentage(for: vehicleSizeToCondition(vehicleProfile.vehicleSize)) {
            totalFee = Int(Double(totalFee) * (1.0 - discountPercentage / 100.0))
            appliedDiscounts.append("\(vehicleProfile.vehicleSize.displayName) \(Int(discountPercentage))%")
        }
        
        // 친환경 차량 할인
        if vehicleProfile.isLowEmission {
            if let discountPercentage = parkingLotProfile.specialConditionDiscounts.getDiscountPercentage(for: .lowEmission) {
                totalFee = Int(Double(totalFee) * (1.0 - discountPercentage / 100.0))
                appliedDiscounts.append("저공해 인증 \(Int(discountPercentage))%")
            }
        }
        
        if vehicleProfile.isElectricHydrogen {
            if let discountPercentage = parkingLotProfile.specialConditionDiscounts.getDiscountPercentage(for: .electricHydrogen) {
                totalFee = Int(Double(totalFee) * (1.0 - discountPercentage / 100.0))
                appliedDiscounts.append("전기/수소 \(Int(discountPercentage))%")
            }
        }
        
        if vehicleProfile.isHybrid {
            if let discountPercentage = parkingLotProfile.specialConditionDiscounts.getDiscountPercentage(for: .hybrid) {
                totalFee = Int(Double(totalFee) * (1.0 - discountPercentage / 100.0))
                appliedDiscounts.append("하이브리드 \(Int(discountPercentage))%")
            }
        }
        
        // 디버깅: 적용된 할인 정보 출력
        if !appliedDiscounts.isEmpty {
            print("🚗 차량 정보: \(vehicleProfile.vehicleSize.displayName), 친환경: \(vehicleProfile.ecoFriendlyType)")
            print("💰 원래 요금: \(originalFee)원")
            print("🎫 적용된 할인: \(appliedDiscounts.joined(separator: ", "))")
            print("💳 최종 요금: \(totalFee)원")
        }
    }
    
    // MARK: - Helper Functions
    private func vehicleSizeToCondition(_ vehicleSize: VehicleSize) -> SpecialCondition {
        switch vehicleSize {
        case .light:
            return .lightCar
        case .normal:
            return .normalCar
        case .medium:
            return .mediumCar
        case .large:
            return .largeCar
        }
    }
    
    // MARK: - Data Persistence
    private func saveParkingLots() {
        // TODO: UserDefaults 또는 Core Data에 저장
    }
    
    // MARK: - Sample Data
    private func createSampleParkingLots() -> [ParkingLotProfile] {
        let sampleCalculator = ParkingFeeCalculator(
            baseFee: 1000,
            baseMinutes: 60,
            unitFee: 500,
            unitMinutes: 30,
            maxFee: 10000,
            freeMinutes: 10
        )
        
        return [
            ParkingLotProfile(
                name: "강남역 주차장",
                address: "서울시 강남구 강남대로 123",
                parkingFeeCalculator: sampleCalculator,
                specialConditionDiscounts: SpecialConditionDiscounts(
                    mildDiscountPercentage: 25.0,
                    severeDiscountPercentage: 60.0,
                    nationalMeritDiscountPercentage: 30.0,
                    exemplaryTaxpayerDiscountPercentage: 10.0,
                    multiChildDiscountPercentage: 20.0,
                    seniorDiscountPercentage: 15.0
                )
            ),
            ParkingLotProfile(
                name: "홍대입구 주차장",
                address: "서울시 마포구 홍대로 456",
                parkingFeeCalculator: sampleCalculator,
                specialConditionDiscounts: SpecialConditionDiscounts(
                    mildDiscountPercentage: 15.0,
                    severeDiscountPercentage: 40.0,
                    nationalMeritDiscountPercentage: 25.0,
                    exemplaryTaxpayerDiscountPercentage: 5.0,
                    multiChildDiscountPercentage: 15.0,
                    seniorDiscountPercentage: 10.0
                )
            )
        ]
    }
}
