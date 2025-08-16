//
//  SettingView.swift
//  ParkingFeeCalculator
//
//  Created by GPT-5 on 8/13/25.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("appColorScheme") private var appColorScheme: String = "system"
    @State private var showingUserProfile = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("계정") {
                    Button(action: {
                        showingUserProfile = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("프로필 관리")
                                    .font(.headline)
                                Text("운전자 및 차량 정보 관리")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section("테마 설정") {
                    Picker("테마", selection: $appColorScheme) {
                        Text("시스템 기본").tag("system")
                        Text("라이트").tag("light")
                        Text("다크").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("앱 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("개발자")
                        Spacer()
                        Text("문주성")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 추후 전역 설정 항목 추가 예정
            }
            .navigationTitle("설정")
            .sheet(isPresented: $showingUserProfile) {
                UserProfileView()
            }
        }
    }
}

#Preview {
    SettingView()
}
