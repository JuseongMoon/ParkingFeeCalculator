//
//  ParkingLotListView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/13/25.
//

import SwiftUI
// import ParkingFeeCore // 임시 제거

struct ParkingLotListView: View {
    @StateObject private var viewModel = TimerListViewModel()
    @State private var isPresentingForm: Bool = false
    @State private var isParkingActive: Bool = false
    @State private var currentParkingLot: ParkingLotProfile?
    

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.parkingLots.isEmpty {
                    List {
                        // 타이머 셀 (항상 표시) - NavigationLink로 감싸지 않음
                        Section {
                            TimerCellView(
                                isParkingActive: $isParkingActive,
                                parkingLotProfile: currentParkingLot
                            )
                            .padding(.top, 20)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                        
                        // 빈 상태 메시지
                        Section {
                            ContentUnavailableView(
                                "주차장이 없습니다",
                                systemImage: "building.2.badge.exclamationmark",
                                description: Text("오른쪽 위 + 버튼으로 주차장을 추가하세요")
                            )
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    List {
                        // 타이머 셀 (항상 표시) - NavigationLink로 감싸지 않음
                        Section {
                            TimerCellView(
                                isParkingActive: $isParkingActive,
                                parkingLotProfile: currentParkingLot
                            )
                            .padding(.top, 20)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                        
                        // 주차장 리스트
                        Section {
                            ForEach(viewModel.parkingLots) { parkingLot in
                                NavigationLink(destination: ParkingLotInfoView(
                                    parkingLotProfile: parkingLot,
                                    isParkingActive: $isParkingActive,
                                    onUpdate: { updatedProfile in
                                        viewModel.updateParkingLot(updatedProfile)
                                        // 현재 주차 중인 주차장이 업데이트된 경우 currentParkingLot도 업데이트
                                        if currentParkingLot?.id == updatedProfile.id {
                                            currentParkingLot = updatedProfile
                                        }
                                    },
                                    onParkingStart: { parkingLot in
                                        // 주차 시작 시 현재 주차장 정보 저장
                                        currentParkingLot = parkingLot
                                    }
                                )) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "parkingsign.circle")
                                            .foregroundStyle(.tint)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(parkingLot.displayName)
                                                .font(.headline)
                                            Text("\(parkingLot.parkingFeeCalculator.additionalFee)원/\(parkingLot.parkingFeeCalculator.additionalMinutes)분")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .onDelete(perform: viewModel.deleteParkingLots)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("주차장 목록")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("주차장 추가")
                }
            }
            .sheet(isPresented: $isPresentingForm) {
                ParkingLotEditView { newParkingLot in
                    viewModel.addParkingLot(newParkingLot)
                }
            }
            .onChange(of: isParkingActive) { _, newValue in
                if !newValue {
                    // 주차가 종료되면 현재 주차장 정보 초기화
                    currentParkingLot = nil
                }
            }
        }
    }
}

#Preview {
    let viewModel = TimerListViewModel()
    viewModel.loadPreviewData()
    return ParkingLotListView()
}


