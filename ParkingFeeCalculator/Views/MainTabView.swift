//
//  MainTabView.swift
//  ParkingFeeCalculator
//
//  Created by GPT-5 on 8/13/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { TimerListView() }
                .tabItem { Label("타이머", systemImage: "clock") }
            NavigationStack { SettingView() }
                .tabItem { Label("설정", systemImage: "gearshape") }
        }
    }
}

#Preview {
    MainTabView()
}

