//
//  TimerListView.swift
//  ParkingFeeCalculator
//
//  Created by GPT-5 on 8/13/25.
//

import SwiftUI

struct TimerListView: View {
    @StateObject private var viewModel = TimerListViewModel()
    @State private var isPresentingForm: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessions.isEmpty {
                    ContentUnavailableView(
                        "타이머가 없습니다",
                        systemImage: "clock.badge.exclamationmark",
                        description: Text("오른쪽 위 + 버튼으로 타이머를 추가하세요")
                    )
                } else {
                    List {
                        ForEach(viewModel.sessions) { session in
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.name.isEmpty ? "주차 타이머" : session.name)
                                        .font(.headline)
                                    Text("기본요금: \(session.tariff.baseFee)원 / 기본시간: \(session.tariff.baseMinutes)분")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .onDelete(perform: viewModel.deleteSessions)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("주차 타이머")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("타이머 추가")
                }
            }
            .sheet(isPresented: $isPresentingForm) {
                TimerFormView { newSession in
                    viewModel.addSession(newSession)
                }
            }
        }
    }
}

#Preview {
    TimerListView()
}


