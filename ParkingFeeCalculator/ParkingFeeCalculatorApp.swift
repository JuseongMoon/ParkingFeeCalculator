//
//  ParkingFeeCalculatorApp.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/13/25.
//

import SwiftUI
import UserNotifications

@main
struct ParkingFeeCalculatorApp: App {
    @StateObject private var userProfileVM = UserProfileViewModel()
    
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
            if granted {
                print("알림 권한이 허용되었습니다.")
            } else {
                print("알림 권한이 거부되었습니다: \(error?.localizedDescription ?? "")")
            }
        }
    }
}
