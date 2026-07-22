//
//  ParkingLotRepository.swift
//  ParkingDomain
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine

/// 주차장 데이터 저장소 인터페이스
public protocol ParkingLotRepository {
    /// 모든 주차장을 가져옵니다
    func getAllParkingLots() -> AnyPublisher<[ParkingLotEntity], Error>

    /// 특정 주차장을 가져옵니다
    func getParkingLot(id: UUID) -> AnyPublisher<ParkingLotEntity?, Error>

    /// 주차장을 저장합니다 (새로 추가하거나 업데이트)
    func saveParkingLot(_ parkingLot: ParkingLotEntity) -> AnyPublisher<ParkingLotEntity, Error>

    /// 주차장을 삭제합니다
    func deleteParkingLot(id: UUID) -> AnyPublisher<Void, Error>

    /// 주차장 목록 변경을 관찰합니다
    var parkingLotsPublisher: AnyPublisher<[ParkingLotEntity], Error> { get }
}