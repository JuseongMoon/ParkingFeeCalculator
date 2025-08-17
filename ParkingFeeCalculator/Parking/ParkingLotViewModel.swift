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
        
        // UserDefaults에서 저장된 주차장 데이터 로드
        if let data = UserDefaults.standard.data(forKey: "savedParkingLots"),
           let savedParkingLots = try? JSONDecoder().decode([ParkingLotProfile].self, from: data) {
            self.parkingLots = savedParkingLots
        } else {
            // 저장된 데이터가 없으면 빈 배열로 시작
            self.parkingLots = []
        }
        
        self.isLoading = false
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
        
        // ParkingFeeCalculator의 통합된 메서드 사용
        let result = parkingLot.parkingFeeCalculator.calculateFee(
            duration: duration,
            vehicleProfile: vehicleProfile,
            driverProfile: driverProfile,
            specialConditionDiscounts: parkingLot.specialConditionDiscounts
        )
        
        return result.finalFee
    }
    
    // MARK: - Data Persistence
    private func saveParkingLots() {
        if let data = try? JSONEncoder().encode(parkingLots) {
            UserDefaults.standard.set(data, forKey: "savedParkingLots")
        }
    }
}
