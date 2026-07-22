//
//  ParkingFeeCalculatorApp.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/13/25.
//
import SwiftUI
import UserNotifications
import os
// // import ParkingFeeCore // 임시 제거  // 임시 제거 - Clean Architecture 패키지 연결 문제
import ParkingShared
// import Security   // ⬅️ Security 연결 후 주석 해제

@main
struct ParkingFeeCalculatorApp: App {
    @StateObject private var userProfileVM = UserProfileViewModel()

    init() {
        #if DEBUG
        // 디버그 모드에서만 App Group 연결 확인
        testAppGroupContainerOpen()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(userProfileVM)
                .onAppear { 
                    requestNotificationPermission()
                }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print(granted ? "알림 권한이 허용되었습니다." : "알림 권한이 거부되었습니다: \(error?.localizedDescription ?? "")")
        }
    }
}

// MARK: - App Group 연결 확인 (디버그용)
func testAppGroupContainerOpen() {
    let groupID = "group.com.ScienceFiction.ParkingFeeCalculator"
    
    // 더 간단한 확인 - 읽기만 시도
    if let shared = UserDefaults(suiteName: groupID) {
        // 기존 데이터 확인만 하고, 새로운 쓰기 작업은 하지 않음
        let hasExistingData = shared.object(forKey: "sharedParkingData") != nil
        print("✅ App Group UserDefaults 사용 가능 (데이터 존재: \(hasExistingData))")
    } else {
        print("❌ App Group UserDefaults 사용 불가")
    }
}

/*
// MARK: - A 사용 (Security 연결 후 주석 해제)
func dumpAppGroupEntitlement() {
    let key = "com.apple.security.application-groups" as CFString
    if let task = SecTaskCreateFromSelf(kCFAllocatorDefault),
       let val  = SecTaskCopyValueForEntitlement(task, key, nil) {
        print("✅ application-groups entitlement:", val)
    } else {
        print("❌ NO application-groups entitlement at runtime")
    }
}
*/
