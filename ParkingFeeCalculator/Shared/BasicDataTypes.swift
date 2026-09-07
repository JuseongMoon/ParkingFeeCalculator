//
//  BasicDataTypes.swift
//  ParkingFeeCalculator
//
//  Created by Claude Code on 9/16/25.
//  기본 데이터 타입들 (Clean Architecture 의존성 제거)
//

import Foundation

// MARK: - 기본값 상수
struct ParkingLotDefaults {
    static let initialFee: Int = 1000
    static let initialMinutes: Int = 30
    static let additionalFee: Int = 500
    static let additionalMinutes: Int = 10
    static let maxFee: Int = 10000
    static let freeMinutes: Int = 10
    static let dailyMaxFee: Int = 20000
    static let nightFlatFee: Int = 5000
    static let nightStartHour: Int = 22
    static let nightEndHour: Int = 6
    static let mildDiscountPercentage: Double = 20.0
    static let severeDiscountPercentage: Double = 50.0
    static let nationalMeritDiscountPercentage: Double = 30.0
    static let exemplaryTaxpayerDiscountPercentage: Double = 10.0
    static let multiChildDiscountPercentage: Double = 30.0
    static let seniorDiscountPercentage: Double = 30.0
    static let largeCarDiscountPercentage: Double = 0.0
    static let electricDiscountPercentage: Double = 20.0
    static let hydrogenDiscountPercentage: Double = 30.0
    static let hybridDiscountPercentage: Double = 10.0
    static let lightCarDiscountPercentage: Double = 20.0
    static let normalCarDiscountPercentage: Double = 0.0
}

// MARK: - 야간 요금 타입
enum NightRateType: String, CaseIterable, Codable {
    case flat = "평야간요금"
    case discount = "야간할인"
    case percentage = "퍼센티지"

    var percentage: Double {
        switch self {
        case .flat:
            return 0.0
        case .discount:
            return 30.0
        case .percentage:
            return 30.0
        }
    }
    var displayName: String {
        switch self {
        case .flat:
            return "정액"
        case .discount:
            return "할인"
        case .percentage:
            return "퍼센트"
        }
    }
}

// MARK: - 장애 등급
enum DisabilityLevel: String, CaseIterable, Codable {
    case none = "해당없음"
    case mild = "경증"
    case severe = "중증"

    /// rawValue 자체가 화면 표시용 한국어 라벨이다.
    var displayName: String { rawValue }
}

// MARK: - 차량 크기
enum VehicleSize: String, CaseIterable, Codable {
    case light = "경차"
    case normal = "일반"
    case large = "대형"

    /// rawValue 자체가 화면 표시용 한국어 라벨이다.
    var displayName: String { rawValue }
}

// MARK: - 시간대별 요금 계층
struct TimeBasedPricingTier: Codable, Equatable {
    // 시작 임계 시간(분): 이 시간 이후부터 본 구간 요금이 적용됩니다.
    var thresholdMinutes: Int
    // 단위 요금(원)
    var feePerUnit: Int
    // 단위 시간(분)
    var unitMinutes: Int

    init(thresholdMinutes: Int, feePerUnit: Int, unitMinutes: Int) {
        self.thresholdMinutes = thresholdMinutes
        self.feePerUnit = feePerUnit
        self.unitMinutes = unitMinutes
    }
}

// MARK: - 기본 주차장 프로필
struct ParkingLotProfile: Codable, Identifiable {
    let id: UUID
    let name: String
    let address: String
    let parkingFeeCalculator: ParkingFeeCalculator
    let specialConditionDiscounts: SpecialConditionDiscounts
    let createdAt: Date
    let updatedAt: Date

    init(id: UUID = UUID(), name: String = "", address: String = "", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.address = address
        self.parkingFeeCalculator = ParkingFeeCalculator()
        self.specialConditionDiscounts = SpecialConditionDiscounts()
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(id: UUID = UUID(), name: String, address: String, parkingFeeCalculator: ParkingFeeCalculator, specialConditionDiscounts: SpecialConditionDiscounts, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.address = address
        self.parkingFeeCalculator = parkingFeeCalculator
        self.specialConditionDiscounts = specialConditionDiscounts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 목록·상세 화면 표시용 이름. 이름이 비어 있으면 자리표시자를 보여준다.
    var displayName: String {
        name.isEmpty ? "미등록 주차장" : name
    }
}

// MARK: - 기본 할인 조건
struct SpecialConditionDiscounts: Codable {
    var disabledDiscount: Double = 0.5
    var seniorDiscount: Double = 0.3
    var electricVehicleDiscount: Double = 0.2
    var mildDiscountPercentage: Double = 20.0
    var severeDiscountPercentage: Double = 50.0
    var nationalMeritDiscountPercentage: Double = 30.0
    var exemplaryTaxpayerDiscountPercentage: Double = 10.0
    var multiChildDiscountPercentage: Double = 30.0
    var seniorDiscountPercentage: Double = 30.0
    var lightCarDiscountPercentage: Double = 20.0
    var normalCarDiscountPercentage: Double = 0.0
    var largeCarDiscountPercentage: Double = 0.0
    var electricDiscountPercentage: Double = 20.0
    var hydrogenDiscountPercentage: Double = 30.0
    var hybridDiscountPercentage: Double = 10.0

    var hasAnyDiscount: Bool {
        return disabledDiscount > 0 || seniorDiscount > 0 || electricVehicleDiscount > 0 ||
               mildDiscountPercentage > 0 || severeDiscountPercentage > 0 || nationalMeritDiscountPercentage > 0
    }

    var displayDescription: String {
        var descriptions: [String] = []
        if disabledDiscount > 0 { descriptions.append("장애인 할인: \(Int(disabledDiscount * 100))%") }
        if seniorDiscount > 0 { descriptions.append("경로우대 할인: \(Int(seniorDiscount * 100))%") }
        if electricVehicleDiscount > 0 { descriptions.append("전기차 할인: \(Int(electricVehicleDiscount * 100))%") }
        if mildDiscountPercentage > 0 { descriptions.append("경증 할인: \(Int(mildDiscountPercentage))%") }
        if severeDiscountPercentage > 0 { descriptions.append("중증 할인: \(Int(severeDiscountPercentage))%") }
        if nationalMeritDiscountPercentage > 0 { descriptions.append("국가유공자 할인: \(Int(nationalMeritDiscountPercentage))%") }
        return descriptions.joined(separator: ", ")
    }

    init() {}

    init(mildDiscountPercentage: Double = 20.0, severeDiscountPercentage: Double = 50.0, nationalMeritDiscountPercentage: Double = 30.0) {
        self.mildDiscountPercentage = mildDiscountPercentage
        self.severeDiscountPercentage = severeDiscountPercentage
        self.nationalMeritDiscountPercentage = nationalMeritDiscountPercentage
    }

    init(mildDiscountPercentage: Double?, severeDiscountPercentage: Double?, nationalMeritDiscountPercentage: Double?, exemplaryTaxpayerDiscountPercentage: Double?, multiChildDiscountPercentage: Double?, seniorDiscountPercentage: Double?, lightCarDiscountPercentage: Double?, normalCarDiscountPercentage: Double?, largeCarDiscountPercentage: Double?, electricDiscountPercentage: Double?, hydrogenDiscountPercentage: Double?, hybridDiscountPercentage: Double?) {
        self.mildDiscountPercentage = mildDiscountPercentage ?? 20.0
        self.severeDiscountPercentage = severeDiscountPercentage ?? 50.0
        self.nationalMeritDiscountPercentage = nationalMeritDiscountPercentage ?? 30.0
        self.exemplaryTaxpayerDiscountPercentage = exemplaryTaxpayerDiscountPercentage ?? 10.0
        self.multiChildDiscountPercentage = multiChildDiscountPercentage ?? 30.0
        self.seniorDiscountPercentage = seniorDiscountPercentage ?? 30.0
        self.lightCarDiscountPercentage = lightCarDiscountPercentage ?? 20.0
        self.normalCarDiscountPercentage = normalCarDiscountPercentage ?? 0.0
        self.largeCarDiscountPercentage = largeCarDiscountPercentage ?? 0.0
        self.electricDiscountPercentage = electricDiscountPercentage ?? 20.0
        self.hydrogenDiscountPercentage = hydrogenDiscountPercentage ?? 30.0
        self.hybridDiscountPercentage = hybridDiscountPercentage ?? 10.0
    }
}

// MARK: - 기본 사용자 프로필
struct DriverProfile: Codable {
    var isDisabled: Bool = false
    var isSenior: Bool = false
    var hasLowIncome: Bool = false
    /// nil 이면 해당 없음. 프로필 화면이 `if let` 과 optional tag 로 다루므로 Optional 로 둔다.
    var disabilityLevel: DisabilityLevel? = nil
    // 감면 대상 조건 — SpecialConditionDiscounts 의 nationalMerit 등과 짝을 이룬다.
    var isNationalMerit: Bool = false
    var isMultiChild: Bool = false
    var isExemplaryTaxpayer: Bool = false

    /// 감면 조건이 하나라도 켜져 있는가. 프로필 화면의 조건 요약 표시에 쓴다.
    var hasAnySpecialCondition: Bool {
        isDisabled || isSenior || hasLowIncome || isNationalMerit || isMultiChild || isExemplaryTaxpayer
    }

    var displayName: String {
        var names: [String] = []
        if isDisabled { names.append("장애인") }
        if isSenior { names.append("경로우대") }
        if hasLowIncome { names.append("저소득층") }
        if isNationalMerit { names.append("국가유공자") }
        if isMultiChild { names.append("다자녀") }
        if isExemplaryTaxpayer { names.append("모범납세자") }
        return names.isEmpty ? "일반" : names.joined(separator: ", ")
    }

    init(isDisabled: Bool = false, isSenior: Bool = false, hasLowIncome: Bool = false, disabilityLevel: DisabilityLevel? = nil,
         isNationalMerit: Bool = false, isMultiChild: Bool = false, isExemplaryTaxpayer: Bool = false) {
        self.isDisabled = isDisabled
        self.isSenior = isSenior
        self.hasLowIncome = hasLowIncome
        self.disabilityLevel = disabilityLevel
        self.isNationalMerit = isNationalMerit
        self.isMultiChild = isMultiChild
        self.isExemplaryTaxpayer = isExemplaryTaxpayer
    }

    var isProfileComplete: Bool {
        return true // 기본적으로 완료된 것으로 간주
    }
}

struct VehicleProfile: Codable {
    var isElectric: Bool = false
    var isHydrogen: Bool = false
    var isHybrid: Bool = false
    var isCompact: Bool = false
    var vehicleSize: VehicleSize = .normal

    init(isElectric: Bool = false, isHydrogen: Bool = false, isHybrid: Bool = false,
         isCompact: Bool = false, vehicleSize: VehicleSize = .normal) {
        self.isElectric = isElectric
        self.isHydrogen = isHydrogen
        self.isHybrid = isHybrid
        self.isCompact = isCompact
        self.vehicleSize = vehicleSize
    }

    /// 친환경차 감면 대상 여부 — 전기·수소·하이브리드 중 하나면 true.
    var isEcoFriendly: Bool { isElectric || isHydrogen || isHybrid }

    var isProfileComplete: Bool {
        return true // 기본적으로 완료된 것으로 간주
    }

    /// 프로필 화면 요약 라벨. DriverProfile.displayName 과 같은 방식으로 속성을 나열한다.
    /// vehicleSize 가 .light 이면 isCompact 라벨이 "경차"와 겹치므로 한 번만 표시한다.
    var displayName: String {
        var names: [String] = [vehicleSize.displayName]
        if isElectric { names.append("전기차") }
        if isHydrogen { names.append("수소차") }
        if isHybrid { names.append("하이브리드") }
        if isCompact && vehicleSize != .light { names.append("경차") }
        return names.joined(separator: ", ")
    }
}

// MARK: - 기본 요금 계산기
struct ParkingFeeCalculator: Codable {
    var initialFee: Int = 1000
    var additionalFee: Int = 500
    var initialMinutes: Int = 30
    var additionalMinutes: Int = 10
    var maxFee: Int? = 10000
    var freeMinutes: Int = 10
    var dailyMaxFee: Int? = 20000
    var nightFlatFee: Int? = 5000
    var nightStartHour: Int? = 22
    var nightEndHour: Int? = 6
    var nightRateType: NightRateType = .flat
    var nightDiscountPercentage: Double = 30.0
    var useTimeBasedPricing: Bool = false
    var pricingTiers: [TimeBasedPricingTier] = []

    var hasNightRate: Bool {
        return nightFlatFee != nil
    }

    init(initialFee: Int = 1000, additionalFee: Int = 500) {
        self.initialFee = initialFee
        self.additionalFee = additionalFee
        self.initialMinutes = 30
        self.additionalMinutes = 10
        self.maxFee = 10000
        self.freeMinutes = 10
        self.dailyMaxFee = 20000
        self.nightFlatFee = 5000
        self.nightStartHour = 22
        self.nightEndHour = 6
        self.nightRateType = .flat
        self.nightDiscountPercentage = 30.0
        self.useTimeBasedPricing = false
        self.pricingTiers = []
    }

    init(initialFee: Int, initialMinutes: Int, additionalFee: Int, additionalMinutes: Int, maxFee: Int, freeMinutes: Int, dailyMaxFee: Int, nightFlatFee: Int, nightStartHour: Int, nightEndHour: Int) {
        self.initialFee = initialFee
        self.initialMinutes = initialMinutes
        self.additionalFee = additionalFee
        self.additionalMinutes = additionalMinutes
        self.maxFee = maxFee
        self.freeMinutes = freeMinutes
        self.dailyMaxFee = dailyMaxFee
        self.nightFlatFee = nightFlatFee
        self.nightStartHour = nightStartHour
        self.nightEndHour = nightEndHour
        self.nightRateType = .flat
        self.nightDiscountPercentage = 30.0
        self.useTimeBasedPricing = false
        self.pricingTiers = []
    }

    init(initialFee: Int, initialMinutes: Int, additionalFee: Int, additionalMinutes: Int, maxFee: Int?, freeMinutes: Int, dailyMaxFee: Int?, nightFlatFee: Int?, nightStartHour: Int?, nightEndHour: Int?, nightRateType: NightRateType = .flat, nightDiscountPercentage: Double? = nil, useTimeBasedPricing: Bool = false, pricingTiers: [TimeBasedPricingTier] = []) {
        self.initialFee = initialFee
        self.initialMinutes = initialMinutes
        self.additionalFee = additionalFee
        self.additionalMinutes = additionalMinutes
        self.maxFee = maxFee
        self.freeMinutes = freeMinutes
        self.dailyMaxFee = dailyMaxFee
        self.nightFlatFee = nightFlatFee
        self.nightStartHour = nightStartHour
        self.nightEndHour = nightEndHour
        self.nightRateType = nightRateType
        self.nightDiscountPercentage = nightDiscountPercentage ?? 30.0
        self.useTimeBasedPricing = useTimeBasedPricing
        self.pricingTiers = pricingTiers
    }
}

// MARK: - 기본 주차 세션 데이터
struct SharedParkingSession: Codable {
    let id: UUID
    let sessionId: String
    let parkingLot: ParkingLotProfile
    let startTime: Date
    let currentFee: Int
    let discountInfo: String?

    init(id: UUID = UUID(), parkingLot: ParkingLotProfile, startTime: Date = Date(), currentFee: Int = 0, discountInfo: String? = nil) {
        self.id = id
        self.sessionId = id.uuidString
        self.parkingLot = parkingLot
        self.startTime = startTime
        self.currentFee = currentFee
        self.discountInfo = discountInfo
    }

    init(startTime: Date, parkingLot: ParkingLotProfile, vehicle: VehicleProfile, driver: DriverProfile, additionalFreeMinutes: Int = 0) {
        self.id = UUID()
        self.sessionId = self.id.uuidString
        self.parkingLot = parkingLot
        self.startTime = startTime
        self.currentFee = 0
        self.discountInfo = nil
    }

    static func fromDictionary(_ dict: [String: Any]) throws -> SharedParkingSession {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let sessionId = dict["sessionId"] as? String,
              let startTimeInterval = dict["startTime"] as? TimeInterval else {
            throw NSError(domain: "SharedParkingSessionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid dictionary format"])
        }

        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let currentFee = dict["currentFee"] as? Int ?? 0
        let discountInfo = dict["discountInfo"] as? String
        let parkingLotName = dict["parkingLotName"] as? String ?? "Unknown"

        let parkingLot = ParkingLotProfile(name: parkingLotName, address: "")

        return SharedParkingSession(id: id, parkingLot: parkingLot, startTime: startTime, currentFee: currentFee, discountInfo: discountInfo)
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "sessionId": sessionId,
            "startTime": startTime.timeIntervalSince1970,
            "currentFee": currentFee,
            "parkingLotName": parkingLot.name
        ]
    }
}

// MARK: - 간단한 주차 세션 매니저
class ParkingSessionManager {
    static let shared = ParkingSessionManager()

    private var _currentSession: SharedParkingSession?
    private let userDefaults = UserDefaults.standard
    private let sessionKey = "currentParkingSession"

    private init() {}

    func currentSession() -> SharedParkingSession? {
        if _currentSession == nil {
            loadSession()
        }
        return _currentSession
    }

    func startSession(_ session: SharedParkingSession) {
        _currentSession = session
        saveSession()
    }

    func endSession() {
        _currentSession = nil
        userDefaults.removeObject(forKey: sessionKey)
    }

    func updateAdditionalFreeMinutes(_ minutes: Int) {
        // 추가 무료 시간 업데이트 로직
        print("추가 무료 시간 업데이트: \(minutes)분")
    }

    var currentDiscountInfo: String? {
        return _currentSession?.discountInfo
    }

    private func loadSession() {
        guard let data = userDefaults.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(SharedParkingSession.self, from: data) else {
            return
        }
        _currentSession = session
    }

    private func saveSession() {
        guard let session = _currentSession else { return }
        if let data = try? JSONEncoder().encode(session) {
            userDefaults.set(data, forKey: sessionKey)
        }
    }
}

// MARK: - 간단한 요금 계산 서비스
class FeeCalculationService {
    static let shared = FeeCalculationService()

    private init() {}

    func calculateFee(for session: SharedParkingSession, at date: Date = Date()) -> FeeCalculationResult {
        let elapsed = date.timeIntervalSince(session.startTime)
        let minutes = Int(elapsed / 60)

        // 기본적인 요금 계산 (시간당 1000원)
        let baseFee = max(1000, (minutes / 60 + 1) * 1000)

        // 간단한 할인 적용
        var finalFee = baseFee
        var discountInfo: String?
        var applicableDiscounts: [DiscountInfo] = []

        if let discount = session.discountInfo {
            finalFee = Int(Double(baseFee) * 0.8) // 20% 할인
            discountInfo = discount
            applicableDiscounts.append(DiscountInfo(name: discount, percentage: 20.0))
        }

        return FeeCalculationResult(
            finalFee: finalFee,
            discountInfo: discountInfo,
            applicableDiscounts: applicableDiscounts
        )
    }
}

// MARK: - 할인 정보
struct DiscountInfo {
    let name: String
    let percentage: Double
}

// MARK: - 요금 계산 결과
struct FeeCalculationResult {
    let finalFee: Int
    let discountInfo: String?
    let applicableDiscounts: [DiscountInfo]
}

// MARK: - 기본 응답 타입
struct ParkingSessionResponse: Codable {
    let sessionId: String
    let status: String
    let nextChangeTime: Date?
    let nextScheduleId: String?

    init(sessionId: String = "", status: String = "success", nextChangeTime: Date? = nil, nextScheduleId: String? = nil) {
        self.sessionId = sessionId
        self.status = status
        self.nextChangeTime = nextChangeTime
        self.nextScheduleId = nextScheduleId
    }
}
