//
//  ManageParkingLotsUseCaseImpl.swift
//  ParkingUI
//
//  Created by ClaudeCode on 9/16/25.
//

import Foundation
import Combine
import ParkingDomain

/// 주차장 관리 Use Case 구현체
public final class ManageParkingLotsUseCaseImpl: ManageParkingLotsUseCase {
    private let parkingLotRepository: ParkingLotRepository

    public init(parkingLotRepository: ParkingLotRepository) {
        self.parkingLotRepository = parkingLotRepository
    }

    // MARK: - ManageParkingLotsUseCase Implementation

    public func getAllParkingLots() -> AnyPublisher<[ParkingLotEntity], Error> {
        return parkingLotRepository.getAllParkingLots()
    }

    public func getParkingLot(id: UUID) -> AnyPublisher<ParkingLotEntity?, Error> {
        return parkingLotRepository.getParkingLot(id: id)
    }

    public func addParkingLot(_ parkingLot: ParkingLotEntity) -> AnyPublisher<ParkingLotEntity, Error> {
        // 비즈니스 규칙 검증
        guard !parkingLot.name.isEmpty else {
            return Fail(error: DomainError.invalidInput("주차장 이름은 필수입니다"))
                .eraseToAnyPublisher()
        }

        guard !parkingLot.address.isEmpty else {
            return Fail(error: DomainError.invalidInput("주차장 주소는 필수입니다"))
                .eraseToAnyPublisher()
        }

        // 중복 이름 체크
        return getAllParkingLots()
            .flatMap { [weak self] existingLots -> AnyPublisher<ParkingLotEntity, Error> in
                guard let self = self else {
                    return Fail(error: DomainError.entityNotFound("Repository unavailable"))
                        .eraseToAnyPublisher()
                }

                let duplicateExists = existingLots.contains { $0.name == parkingLot.name && $0.id != parkingLot.id }

                if duplicateExists {
                    return Fail(error: DomainError.businessRuleViolation("동일한 이름의 주차장이 이미 존재합니다"))
                        .eraseToAnyPublisher()
                }

                return self.parkingLotRepository.saveParkingLot(parkingLot)
                    .handleEvents(receiveOutput: { _ in
                        print("➕ [ManageParkingLotsUseCase] 주차장 추가 완료: \(parkingLot.name)")
                    })
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func updateParkingLot(_ parkingLot: ParkingLotEntity) -> AnyPublisher<ParkingLotEntity, Error> {
        // 기본 검증
        guard !parkingLot.name.isEmpty else {
            return Fail(error: DomainError.invalidInput("주차장 이름은 필수입니다"))
                .eraseToAnyPublisher()
        }

        return parkingLotRepository.saveParkingLot(parkingLot)
            .handleEvents(receiveOutput: { _ in
                print("🔄 [ManageParkingLotsUseCase] 주차장 업데이트 완료: \(parkingLot.name)")
            })
            .eraseToAnyPublisher()
    }

    public func deleteParkingLot(id: UUID) -> AnyPublisher<Void, Error> {
        return parkingLotRepository.deleteParkingLot(id: id)
            .handleEvents(receiveOutput: { _ in
                print("🗑 [ManageParkingLotsUseCase] 주차장 삭제 완료: \(id)")
            })
            .eraseToAnyPublisher()
    }

    public var parkingLotsPublisher: AnyPublisher<[ParkingLotEntity], Error> {
        return parkingLotRepository.parkingLotsPublisher
    }
}