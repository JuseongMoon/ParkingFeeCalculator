//
//  UserProfileViewModel.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/16/25.
//

import Foundation
import Combine
// import ParkingFeeCore // 임시 제거

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var driverProfile: DriverProfile = DriverProfile()
    @Published var vehicleProfile: VehicleProfile = VehicleProfile()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadProfiles()
    }
    
    // MARK: - Profile Management
    func loadProfiles() {
        isLoading = true
        
        // TODO: UserDefaults 또는 Core Data에서 로드
        // 임시로 기본값 사용
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    func saveProfiles() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: UserDefaults 또는 Core Data에 저장
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 지연
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func updateDriverProfile(_ profile: DriverProfile) {
        driverProfile = profile
    }
    
    func updateVehicleProfile(_ profile: VehicleProfile) {
        vehicleProfile = profile
    }
    
    // MARK: - Validation
    var isDriverProfileComplete: Bool {
        return driverProfile.isProfileComplete
    }
    
    var isVehicleProfileComplete: Bool {
        return vehicleProfile.isProfileComplete
    }
    
    var areProfilesComplete: Bool {
        return isDriverProfileComplete && isVehicleProfileComplete
    }
    
    // MARK: - Profile Actions
    func resetDriverProfile() {
        driverProfile = DriverProfile()
    }
    
    func resetVehicleProfile() {
        vehicleProfile = VehicleProfile()
    }
    
    func resetAllProfiles() {
        resetDriverProfile()
        resetVehicleProfile()
    }
    
    // MARK: - Fee Calculation Helper
    func getCurrentDriverProfile() -> DriverProfile {
        return driverProfile
    }
    
    func getCurrentVehicleProfile() -> VehicleProfile {
        return vehicleProfile
    }
}
