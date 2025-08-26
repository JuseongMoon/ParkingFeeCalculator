//
//  ParkingLiveActivityController.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import ActivityKit
import Foundation
import SwiftUI
import ParkingFeeCore

final class ParkingLiveActivityController: ObservableObject {
    private var activity: Activity<ParkingAttributes>?
    private var session: SharedParkingSession?
    
    func start(startedAt: Date, lotName: String, initialFee: Int, 
               additionalFee: Int, additionalMinutes: Int, currentFee: Int, 
               additionalFreeMinutes: Int = 0, discountInfo: String? = nil) {
        print("🚀 === Live Activity 시작 (ParkingFeeCore 사용) ===")
        print("ActivityAuthorizationInfo().areActivitiesEnabled: \(ActivityAuthorizationInfo().areActivitiesEnabled)")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { 
            print("❌ Live Activities가 비활성화되어 있습니다.")
            return 
        }
        
        // 현재 세션 정보 가져오기
        guard let currentSession = ParkingSessionManager.shared.currentSession() else {
            print("❌ 활성 세션이 없어서 Live Activity를 시작할 수 없습니다.")
            return
        }
        
        self.session = currentSession
        
        let attributes = ParkingAttributes(parkingLotName: lotName)
        let calculator = currentSession.parkingLot.parkingFeeCalculator
        let content = ParkingAttributes.ContentState(
            startTime: startedAt,
            parkingLotName: lotName,
            initialFee: calculator.initialFee,
            initialMinutes: calculator.initialMinutes,
            additionalFee: calculator.additionalFee,
            additionalMinutes: calculator.additionalMinutes,
            freeMinutes: calculator.freeMinutes,
            additionalFreeMinutes: additionalFreeMinutes,
            maxFee: calculator.maxFee,
            discountInfo: discountInfo
        )
        
        do {
            print("✅ Live Activity 요청 시도...")
            print("Attributes: \(attributes)")
            print("Content: \(content)")
            
            activity = try Activity<ParkingAttributes>.request(
                attributes: attributes,
                content: .init(state: content, staleDate: nil),
                pushType: nil
            )
            
            print("✅ Live Activity 시작 성공!")
            print("Activity ID: \(activity?.id ?? "Unknown")")
            
            // Darwin Notification 수신 설정 (설정 변경 시에만 업데이트)
            DataChangeNotifier.shared.observeAllChanges { [weak self] in
                self?.updateFromSession()
            }
            
        } catch {
            print("❌ Live Activity 시작 실패: \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }
    
    func update(currentFee: Int, startedAt: Date, additionalFreeMinutes: Int = 0, discountInfo: String? = nil) {
        guard let activity, let session = self.session else { return }
        
        let calculator = session.parkingLot.parkingFeeCalculator
        let content = ParkingAttributes.ContentState(
            startTime: startedAt,
            parkingLotName: session.parkingLot.name,
            initialFee: calculator.initialFee,
            initialMinutes: calculator.initialMinutes,
            additionalFee: calculator.additionalFee,
            additionalMinutes: calculator.additionalMinutes,
            freeMinutes: calculator.freeMinutes,
            additionalFreeMinutes: additionalFreeMinutes,
            maxFee: calculator.maxFee,
            discountInfo: discountInfo
        )
        Task { await activity.update(.init(state: content, staleDate: nil)) }
    }
    
    func end() {
        // Activity 종료
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.activity = nil
        self.session = nil
        
        print("🛑 Live Activity 종료 완료")
    }
    
    // MARK: - 세션 기반 업데이트 (설정 변경 시에만)
    
    private func updateFromSession() {
        guard let currentSession = ParkingSessionManager.shared.currentSession(),
              let activity = activity else {
            print("❌ [Live Activity] 세션 또는 Activity가 없습니다.")
            return
        }
        
        let calculator = currentSession.parkingLot.parkingFeeCalculator
        let discountInfo = currentSession.discountInfo
        
        let content = ParkingAttributes.ContentState(
            startTime: currentSession.startTime,
            parkingLotName: currentSession.parkingLot.name,
            initialFee: calculator.initialFee,
            initialMinutes: calculator.initialMinutes,
            additionalFee: calculator.additionalFee,
            additionalMinutes: calculator.additionalMinutes,
            freeMinutes: calculator.freeMinutes,
            additionalFreeMinutes: currentSession.additionalFreeMinutes,
            maxFee: calculator.maxFee,
            discountInfo: discountInfo
        )
        
        Task {
            await activity.update(.init(state: content, staleDate: nil))
            print("📱 [Live Activity] 설정 변경 업데이트 완료")
        }
    }
}
