//
//  ParkingLotListView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/13/25.
//

import SwiftUI

struct ParkingLotListView: View {
    @StateObject private var viewModel = TimerListViewModel()
    @State private var isPresentingForm: Bool = false
    @State private var isParkingActive: Bool = false
    @State private var currentParkingLot: ParkingLotProfile?
    
    // MARK: - 테스트용 변수 (출시 시 제거 예정)
    @State private var testTimeOffset: TimeInterval = 0

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.parkingLots.isEmpty {
                    List {
                        // 타이머 셀 (항상 표시) - NavigationLink로 감싸지 않음
                        Section {
                            TimerCellView(
                                isParkingActive: $isParkingActive,
                                parkingLotProfile: currentParkingLot,
                                testTimeOffset: testTimeOffset // 테스트용 시간 오프셋 전달
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
                                parkingLotProfile: currentParkingLot,
                                testTimeOffset: testTimeOffset // 테스트용 시간 오프셋 전달
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
            .onChange(of: isParkingActive) { newValue in
                if !newValue {
                    // 주차가 종료되면 현재 주차장 정보 초기화
                    currentParkingLot = nil
                }
            }
            // MARK: - 테스트용 플로팅 버튼 (출시 시 제거 예정)
            .overlay(
                Group {
                    if isParkingActive {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    // 시간 추가 버튼
                                    Button(action: {
                                        testTimeOffset += 60 // 1분 추가
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                    .accessibilityLabel("테스트용 시간 1분 추가")
                                    
                                    // 시간 감소 버튼
                                    Button(action: {
                                        testTimeOffset -= 60 // 1분 감소
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                    .accessibilityLabel("테스트용 시간 1분 감소")
                                    
                                    // 시간 리셋 버튼
                                    Button(action: {
                                        testTimeOffset = 0 // 시간 오프셋 리셋
                                    }) {
                                        Image(systemName: "arrow.clockwise.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.orange)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                    .accessibilityLabel("테스트용 시간 리셋")
                                }
                                .padding(.trailing, 20)
                                .padding(.bottom, 100) // 탭바 위에 위치하도록 조정
                            }
                        }
                    }
                }
            )
        }
    }
}

#Preview {
    let viewModel = TimerListViewModel()
    viewModel.loadPreviewData()
    return ParkingLotListView()
}


