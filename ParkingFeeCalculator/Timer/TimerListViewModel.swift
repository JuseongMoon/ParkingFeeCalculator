//
//  TimerListViewModel.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/13/25.
//

import Foundation
import Combine
import ParkingFeeCore

@MainActor
class TimerListViewModel: ObservableObject {
    @Published private(set) var sessions: [ParkingSession] = []
    @Published private(set) var parkingLots: [ParkingLotProfile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedSession: ParkingSession?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSessions()
        loadParkingLots()
    }
    
    // MARK: - Session Management
    func loadSessions() {
        isLoading = true
        
        // TODO: UserDefaults 또는 Core Data에서 로드
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    func addSession(_ session: ParkingSession) {
        sessions.append(session)
        saveSessions()
    }
    
    func deleteSessions(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        saveSessions()
    }
    
    // MARK: - Parking Lot Management
    func loadParkingLots() {
        // TODO: UserDefaults 또는 Core Data에서 로드
        // 실제 앱에서는 빈 상태로 시작
    }
    
    func addParkingLot(_ parkingLot: ParkingLotProfile) {
        parkingLots.append(parkingLot)
        saveParkingLots()
    }
    
    func deleteParkingLots(at offsets: IndexSet) {
        parkingLots.remove(atOffsets: offsets)
        saveParkingLots()
    }
    
    func updateParkingLot(_ parkingLot: ParkingLotProfile) {
        if let index = parkingLots.firstIndex(where: { $0.id == parkingLot.id }) {
            parkingLots[index] = parkingLot
            saveParkingLots()
        }
    }
    
    func updateSession(_ session: ParkingSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            saveSessions()
        }
    }
    
    func endSession(_ session: ParkingSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index].endSession()
            saveSessions()
        }
    }
    
    func selectSession(_ session: ParkingSession) {
        selectedSession = session
    }
    
    // MARK: - Session Queries
    var activeSessions: [ParkingSession] {
        return sessions.filter { $0.isActive }
    }
    
    var completedSessions: [ParkingSession] {
        return sessions.filter { $0.isCompleted }
    }
    
    var totalActiveSessions: Int {
        return activeSessions.count
    }
    
    var totalCompletedSessions: Int {
        return completedSessions.count
    }
    
    // MARK: - Fee Calculations
    func calculateTotalFees() -> Int {
        return sessions.reduce(0) { $0 + $1.totalFee }
    }
    
    func calculateActiveFees() -> Int {
        return activeSessions.reduce(0) { $0 + $1.totalFee }
    }
    
    func calculateCompletedFees() -> Int {
        return completedSessions.reduce(0) { $0 + $1.totalFee }
    }
    
    // MARK: - Statistics
    func getAverageSessionDuration() -> TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(sessions.count)
    }
    
    func getMostUsedParkingLot() -> ParkingLotProfile? {
        let parkingLotCounts = Dictionary(grouping: sessions, by: { $0.parkingLotProfile.id })
            .mapValues { $0.count }
        
        return parkingLotCounts.max(by: { $0.value < $1.value })
            .flatMap { parkingLotId in
                sessions.first { $0.parkingLotProfile.id == parkingLotId.key }?.parkingLotProfile
            }
    }
    
    // MARK: - Data Persistence
    private func saveSessions() {
        // TODO: UserDefaults 또는 Core Data에 저장
    }
    
    private func saveParkingLots() {
        // TODO: UserDefaults 또는 Core Data에 저장
    }
    
    // MARK: - Preview Helper
    func loadPreviewData() {
        let sampleParkingLot = ParkingLotProfile(
            name: "테스트 주차장",
            address: "서울시 강남구 테헤란로 123",
            parkingFeeCalculator: ParkingFeeCalculator(
                initialFee: 1000,
                initialMinutes: 30,
                additionalFee: 500,
                additionalMinutes: 10,
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
        parkingLots.append(sampleParkingLot)
    }
    
    // MARK: - Session Actions
    func clearCompletedSessions() {
        sessions.removeAll { $0.isCompleted }
        saveSessions()
    }
    
    func clearAllSessions() {
        sessions.removeAll()
        saveSessions()
    }
    
    func exportSessions() -> String {
        // TODO: CSV 또는 JSON 형태로 내보내기
        return "세션 내보내기 기능 구현 예정"
    }
}


