//
//  FeeCalculationUtilities.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/26/25.
//

import Foundation

/// 주차비 계산 관련 순수 함수 유틸리티
public enum FeeCalculationUtilities {
    
    /// 다음 요금 변경 시점을 계산합니다
    /// - Parameters:
    ///   - session: 현재 주차 세션
    ///   - after: 기준 시간 (기본값: 현재)
    /// - Returns: 다음 요금 변경 시점, 없으면 nil
    public static func nextFeeChangeTime(
        for session: SharedParkingSession,
        after date: Date = Date()
    ) -> Date? {
        let calculator = session.parkingLot.parkingFeeCalculator
        let elapsed = date.timeIntervalSince(session.startTime)
        let elapsedMinutes = Int(elapsed / 60)
        
        // 총 무료 시간
        let totalFreeMinutes = calculator.freeMinutes + session.additionalFreeMinutes
        
        // 아직 무료 시간 내라면
        if elapsedMinutes < totalFreeMinutes {
            return session.startTime.addingTimeInterval(TimeInterval(totalFreeMinutes * 60))
        }
        
        // 과금 시작 후 경과 시간
        let chargeableMinutes = elapsedMinutes - totalFreeMinutes
        
        // 초기 요금 구간 내라면
        if chargeableMinutes < calculator.initialMinutes {
            return session.startTime.addingTimeInterval(
                TimeInterval((totalFreeMinutes + calculator.initialMinutes) * 60)
            )
        }
        
        // 시간 구간별 요금제를 사용하는 경우
        if calculator.useTimeBasedPricing && !calculator.pricingTiers.isEmpty {
            return nextTierChangeTime(
                session: session,
                chargeableMinutes: chargeableMinutes,
                totalFreeMinutes: totalFreeMinutes
            )
        }
        
        // 일반 요금제: 다음 추가 요금 단위
        let minutesPastInitial = chargeableMinutes - calculator.initialMinutes
        let currentUnit = minutesPastInitial / calculator.additionalMinutes
        let nextUnitMinutes = (currentUnit + 1) * calculator.additionalMinutes + calculator.initialMinutes
        
        return session.startTime.addingTimeInterval(
            TimeInterval((totalFreeMinutes + nextUnitMinutes) * 60)
        )
    }
    
    /// 시간 구간별 요금제에서 다음 변경 시점 계산
    private static func nextTierChangeTime(
        session: SharedParkingSession,
        chargeableMinutes: Int,
        totalFreeMinutes: Int
    ) -> Date? {
        let calculator = session.parkingLot.parkingFeeCalculator
        let sortedTiers = calculator.pricingTiers.sorted { $0.thresholdMinutes < $1.thresholdMinutes }
        
        // 현재 속한 구간 찾기
        for tier in sortedTiers {
            if chargeableMinutes < tier.thresholdMinutes {
                return session.startTime.addingTimeInterval(
                    TimeInterval((totalFreeMinutes + tier.thresholdMinutes) * 60)
                )
            }
        }
        
        // 마지막 구간에서 다음 단위 시간
        if let lastTier = sortedTiers.last {
            let minutesPastThreshold = chargeableMinutes - lastTier.thresholdMinutes
            let currentUnit = minutesPastThreshold / lastTier.unitMinutes
            let nextUnitMinutes = (currentUnit + 1) * lastTier.unitMinutes + lastTier.thresholdMinutes
            
            return session.startTime.addingTimeInterval(
                TimeInterval((totalFreeMinutes + nextUnitMinutes) * 60)
            )
        }
        
        return nil
    }
    
    /// 특정 기간 동안의 모든 요금 변경 시점들을 반환
    /// - Parameters:
    ///   - session: 주차 세션
    ///   - from: 시작 시간
    ///   - duration: 기간 (시간)
    /// - Returns: 요금 변경 시점들의 배열
    public static func getFeeChangePoints(
        for session: SharedParkingSession,
        from startDate: Date,
        duration: TimeInterval
    ) -> [Date] {
        var changePoints: [Date] = []
        var currentDate = startDate
        let endDate = startDate.addingTimeInterval(duration)
        
        // 최대 100개 변경점까지만 (무한루프 방지)
        let maxPoints = 100
        var pointCount = 0
        
        while let nextChange = nextFeeChangeTime(for: session, after: currentDate),
              nextChange <= endDate,
              pointCount < maxPoints {
            changePoints.append(nextChange)
            currentDate = nextChange.addingTimeInterval(1) // 1초 후로 이동
            pointCount += 1
        }
        
        return changePoints
    }
    
    /// 야간 시간대 시작/종료 시점 계산
    /// - Parameters:
    ///   - session: 주차 세션
    ///   - from: 시작 시간
    ///   - to: 종료 시간
    /// - Returns: 야간 시간대 전환 시점들
    public static func getNightRateChangePoints(
        for session: SharedParkingSession,
        from startDate: Date,
        to endDate: Date
    ) -> [Date] {
        let calculator = session.parkingLot.parkingFeeCalculator
        guard let nightStartHour = calculator.nightStartHour,
              let nightEndHour = calculator.nightEndHour else {
            return []
        }
        
        var changePoints: [Date] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            // 당일 야간 시작 시간
            if let nightStart = calendar.date(
                bySettingHour: nightStartHour,
                minute: 0,
                second: 0,
                of: currentDate
            ), nightStart > startDate && nightStart <= endDate {
                changePoints.append(nightStart)
            }
            
            // 다음날 야간 종료 시간
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            if let nightEnd = calendar.date(
                bySettingHour: nightEndHour,
                minute: 0,
                second: 0,
                of: nightEndHour < nightStartHour ? nextDay : currentDate
            ), nightEnd > startDate && nightEnd <= endDate {
                changePoints.append(nightEnd)
            }
            
            // 다음 날로 이동
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = tomorrow
        }
        
        return changePoints.sorted()
    }
    
    /// 일일 최대 요금 도달 시점 계산
    /// - Parameters:
    ///   - session: 주차 세션
    ///   - from: 시작 시간
    /// - Returns: 일일 최대 요금 도달 예상 시점
    public static func dailyMaxFeeReachTime(
        for session: SharedParkingSession,
        from date: Date = Date()
    ) -> Date? {
        guard let dailyMax = session.parkingLot.parkingFeeCalculator.dailyMaxFee else {
            return nil
        }
        
        // 이진 검색으로 최대 요금 도달 시점 찾기
        var low: TimeInterval = 0
        var high: TimeInterval = 86400 // 24시간
        let tolerance: TimeInterval = 60 // 1분 단위 정확도
        
        while high - low > tolerance {
            let mid = (low + high) / 2
            let checkDate = session.startTime.addingTimeInterval(mid)
            let fee = FeeCalculationService.shared.calculateFee(
                for: session,
                at: checkDate
            ).finalFee
            
            if fee >= dailyMax {
                high = mid
            } else {
                low = mid
            }
        }
        
        let resultDate = session.startTime.addingTimeInterval(high)
        
        // 실제로 최대 요금에 도달했는지 확인
        let finalFee = FeeCalculationService.shared.calculateFee(
            for: session,
            at: resultDate
        ).finalFee
        
        return finalFee >= dailyMax ? resultDate : nil
    }
    
    /// 위젯 타임라인을 위한 모든 중요 변경 시점 계산
    /// - Parameters:
    ///   - session: 주차 세션
    ///   - maxDuration: 최대 기간 (기본값: 24시간)
    /// - Returns: 정렬된 변경 시점 배열
    public static func getAllSignificantChangePoints(
        for session: SharedParkingSession,
        maxDuration: TimeInterval = 86400
    ) -> [Date] {
        let startDate = session.startTime
        let endDate = startDate.addingTimeInterval(maxDuration)
        
        var allPoints: Set<Date> = []
        
        // 요금 변경 시점들
        let feeChangePoints = getFeeChangePoints(
            for: session,
            from: startDate,
            duration: maxDuration
        )
        allPoints.formUnion(feeChangePoints)
        
        // 야간 요금 전환 시점들
        let nightChangePoints = getNightRateChangePoints(
            for: session,
            from: startDate,
            to: endDate
        )
        allPoints.formUnion(nightChangePoints)
        
        // 일일 최대 요금 도달 시점
        if let maxFeeTime = dailyMaxFeeReachTime(for: session, from: startDate),
           maxFeeTime <= endDate {
            allPoints.insert(maxFeeTime)
        }
        
        return Array(allPoints).sorted()
    }
}