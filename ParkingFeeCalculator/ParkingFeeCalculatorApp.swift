//
//  ParkingFeeCalculatorApp.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/13/25.
//

import SwiftUI

@main
struct ParkingFeeCalculatorApp: App {
    @StateObject private var userProfileVM = UserProfileViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(userProfileVM)
        }
    }
}
