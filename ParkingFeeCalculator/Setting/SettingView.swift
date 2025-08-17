//
//  SettingView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/13/25.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("appColorScheme") private var appColorScheme: String = "system"
    @StateObject private var settingViewModel = SettingViewModel()
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
                
                Section("알림 설정") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("주차비 알림")
                                .font(.headline)
                            Text("설정된 금액 이상일 때 알림")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $settingViewModel.isParkingFeeAlertEnabled)
                            .labelsHidden()
                    }
                    
                    if settingViewModel.isParkingFeeAlertEnabled {
                        Stepper(value: $settingViewModel.parkingFeeAlertThreshold, in: 1000...1_000_000, step: 1000) {
                            row("알림 기준 금액", suffix: "원", value: settingViewModel.parkingFeeAlertThreshold)
                        }
                    }
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
    
    private func row(_ title: String, suffix: String, value: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)\(suffix)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingView()
}
