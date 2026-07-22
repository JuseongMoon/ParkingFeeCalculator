//
//  ManageParkingLotsUseCase.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine

/// 주차장 관리 Use Case 인터페이스
public protocol ManageParkingLotsUseCase {
    /// 모든 주차장을 가져옵니다
    func getAllParkingLots() -> AnyPublisher<[ParkingLotEntity], Error>

    /// 특정 주차장을 가져옵니다
    func getParkingLot(id: UUID) -> AnyPublisher<ParkingLotEntity?, Error>

    /// 새 주차장을 추가합니다
    func addParkingLot(_ parkingLot: ParkingLotEntity) -> AnyPublisher<ParkingLotEntity, Error>

    /// 주차장 정보를 업데이트합니다
    func updateParkingLot(_ parkingLot: ParkingLotEntity) -> AnyPublisher<ParkingLotEntity, Error>

    /// 주차장을 삭제합니다
    func deleteParkingLot(id: UUID) -> AnyPublisher<Void, Error>

    /// 주차장 목록을 관찰합니다 (실시간 업데이트)
    var parkingLotsPublisher: AnyPublisher<[ParkingLotEntity], Error> { get }
}