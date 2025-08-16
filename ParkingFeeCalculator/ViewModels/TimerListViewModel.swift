//
//  TimerListViewModel.swift
//  ParkingFeeCalculator
//
//  Created by GPT-5 on 8/13/25.
//

import Foundation

final class TimerListViewModel: ObservableObject {
    @Published private(set) var sessions: [ParkingSession] = []

    func addSession(_ session: ParkingSession) {
        sessions.append(session)
    }

    func deleteSessions(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
    }
}


