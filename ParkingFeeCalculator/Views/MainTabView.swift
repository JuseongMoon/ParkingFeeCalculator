//
//  MainTabView.swift
//  ParkingFeeCalculator
//
//  Created by GPT-5 on 8/13/25.
//

import SwiftUI

struct MainTabView: View {
    @AppStorage("appColorScheme") private var appColorScheme: String = "system"

    var colorScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some View {
        TabView {
            NavigationStack { 
                ParkingLotListView() 
            }
            .tabItem { 
                Label("주차장", systemImage: "parkingsign.circle")
            }
            
            NavigationStack { 
                SettingView() 
            }
            .tabItem { 
                Label("설정", systemImage: "gearshape") 
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

#Preview {
    MainTabView()
}
