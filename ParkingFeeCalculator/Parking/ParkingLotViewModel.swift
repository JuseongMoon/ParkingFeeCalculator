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
    // MARK: - Published Properties
    @Published var parkingLots: [ParkingLotProfile] = []
    @Published var selectedParkingLot: ParkingLotProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Data Management
    private let userDefaults = UserDefaults.standard
    private let parkingLotsKey = "parkingLots"

    init() {
        loadParkingLots()
    }

    // MARK: - Parking Lot Management
    func loadParkingLots() {
        isLoading = true
        errorMessage = nil

        // UserDefaults에서 주차장 데이터 로드
        if let data = userDefaults.data(forKey: parkingLotsKey),
           let decodedLots = try? JSONDecoder().decode([ParkingLotProfile].self, from: data) {
            self.parkingLots = decodedLots
            print("✅ [ParkingLotViewModel] 주차장 로드 성공: \(decodedLots.count)개")
        } else {
            // 기본 데이터 없으면 빈 배열
            self.parkingLots = []
            print("ℹ️ [ParkingLotViewModel] 저장된 주차장 데이터 없음")
        }

        isLoading = false
    }

    func addParkingLot(_ parkingLot: ParkingLotProfile) {
        isLoading = true
        errorMessage = nil

        // 배열에 추가
        parkingLots.append(parkingLot)

        // UserDefaults에 저장
        saveParkingLots()

        print("✅ [ParkingLotViewModel] 주차장 추가 성공: \(parkingLot.name)")
        isLoading = false
    }

    func updateParkingLot(_ parkingLot: ParkingLotProfile) {
        isLoading = true
        errorMessage = nil

        // 기존 항목 찾아서 업데이트
        if let index = parkingLots.firstIndex(where: { $0.id == parkingLot.id }) {
            parkingLots[index] = parkingLot
            saveParkingLots()
            print("✅ [ParkingLotViewModel] 주차장 업데이트 성공: \(parkingLot.name)")
        } else {
            errorMessage = "업데이트할 주차장을 찾을 수 없습니다."
            print("❌ [ParkingLotViewModel] 주차장 업데이트 실패: ID를 찾을 수 없음")
        }

        isLoading = false
    }

    func deleteParkingLot(at offsets: IndexSet) {
        parkingLots.remove(atOffsets: offsets)
        saveParkingLots()
        print("✅ [ParkingLotViewModel] 주차장 삭제 완료")
    }

    func deleteParkingLot(id: UUID) {
        parkingLots.removeAll { $0.id == id }
        saveParkingLots()
        print("✅ [ParkingLotViewModel] 주차장 삭제 완료: ID \(id)")
    }

    // MARK: - Private Methods
    private func saveParkingLots() {
        do {
            let encodedData = try JSONEncoder().encode(parkingLots)
            userDefaults.set(encodedData, forKey: parkingLotsKey)
            print("✅ [ParkingLotViewModel] 주차장 데이터 저장 완료")
        } catch {
            errorMessage = "데이터 저장에 실패했습니다."
            print("❌ [ParkingLotViewModel] 주차장 데이터 저장 실패: \(error)")
        }
    }
}