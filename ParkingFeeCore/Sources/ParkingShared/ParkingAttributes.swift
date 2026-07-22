//
//  ParkingAttributes.swift
//  ParkingShared (Swift Package)
//
//  Created by Claude Code on 8/27/25.
//  Optimized for APNs 4KB limit on 9/2/25.
//  Moved to ParkingShared for package compilation
//

import Foundation

/// APNs Push 페이로드 4KB 제한을 고려하여 최적화된 Live Activity Attributes
/// ActivityKit 의존성을 제거하여 Swift Package에서 사용 가능
public struct ParkingAttributes: Codable, Hashable {

    /// 최소 필드만 포함한 ContentState (APNs 4KB 제한 준수)
    public struct ContentState: Codable, Hashable {
        // 필수 표시 필드만 포함 (서버에서 전송)
        public var startTime: Date              // 8 bytes (Double)
        public var lotName: String              // 변수 길이 (최대 20자로 제한)
        public var fee: Int                     // 4 bytes (Int32)
        public var discount: String?            // 옵셔널 (최대 10자로 제한)
        public var nextChange: Date?            // 8 bytes (옵셔널)

        // 계산 필드 (페이로드에 포함되지 않음, 로컬에서 계산)
        public var elapsedSeconds: TimeInterval {
            Date().timeIntervalSince(startTime)
        }

        public init(
            startTime: Date,
            parkingLotName: String,
            currentFee: Int,
            discountInfo: String? = nil,
            nextChangeDate: Date? = nil
        ) {
            self.startTime = startTime
            // 길이 제한으로 페이로드 최적화
            self.lotName = String(parkingLotName.prefix(20))
            self.fee = currentFee
            self.discount = discountInfo.map { String($0.prefix(10)) }
            self.nextChange = nextChangeDate
        }

        // MARK: - 레거시 호환성 (기존 코드와의 호환성 유지)

        /// 레거시 호환을 위한 parkingLotName 접근자
        public var parkingLotName: String {
            get { lotName }
            set { lotName = String(newValue.prefix(20)) }
        }

        /// 레거시 호환을 위한 currentFee 접근자
        public var currentFee: Int {
            get { fee }
            set { fee = newValue }
        }

        /// 레거시 호환을 위한 discountInfo 접근자
        public var discountInfo: String? {
            get { discount }
            set { discount = newValue.map { String($0.prefix(10)) } }
        }

        /// 레거시 호환을 위한 nextChangeDate 접근자
        public var nextChangeDate: Date? {
            get { nextChange }
            set { nextChange = newValue }
        }
    }

    // Attributes는 Live Activity 생성 시에만 설정되므로 최소한으로 유지
    public var lotName: String  // 축약된 필드명으로 페이로드 크기 절약

    public init(parkingLotName: String) {
        // 길이 제한으로 페이로드 최적화
        self.lotName = String(parkingLotName.prefix(20))
    }

    // MARK: - 레거시 호환성 접근자

    /// 레거시 호환을 위한 parkingLotName 접근자
    public var parkingLotName: String {
        get { lotName }
        set { lotName = String(newValue.prefix(20)) }
    }
}

// MARK: - APNs Push 페이로드 예상 크기 계산 (디버깅용)
public extension ParkingAttributes.ContentState {

    /// 예상 JSON 페이로드 크기를 바이트 단위로 반환합니다
    var estimatedPayloadSize: Int {
        // JSON 페이로드 구조 예상:
        // {"aps":{"timestamp":1693747200,"event":"update","content-state":{...}}}

        let baseAPSSize = 50  // aps 헤더 + timestamp + event

        let contentStateSize: Int =
            8 +                           // startTime (Date as timestamp)
            lotName.utf8.count + 4 +      // lotName + JSON quotes/comma
            String(fee).count + 2 +       // fee + comma
            (discount?.utf8.count ?? 0) + 6 +  // discount + JSON quotes/null
            (nextChange != nil ? 8 : 4)   // nextChange timestamp or null

        return baseAPSSize + contentStateSize
    }

    /// APNs 4KB 제한을 준수하는지 확인합니다
    var isWithin4KBLimit: Bool {
        return estimatedPayloadSize < 4096
    }

    /// 페이로드 크기 정보를 디버깅용으로 반환합니다
    var payloadSizeInfo: String {
        let size: Int = estimatedPayloadSize
        let limit: Int = 4096
        let percentage: Double = Double(size) / Double(limit) * 100
        let status: String = isWithin4KBLimit ? "✅" : "❌"

        return """
        예상 페이로드 크기: \(size) bytes / \(limit) bytes (\(String(format: "%.1f", percentage))%)
        4KB 제한 준수: \(status)
        """
    }
}