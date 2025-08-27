//
//  FeeScheduler.swift
//  ParkingFeeCore
//
//  Created by Claude Code on 8/27/25.
//

import Foundation

/// 요금 변경 시점을 계산하여 최적의 업데이트 스케줄링을 지원하는 서비스
public struct FeeScheduler {
    
    /// 다음 요금 변경 시점을 계산합니다
    /// - Parameters:
    ///   - startTime: 주차 시작 시간
    ///   - currentTime: 현재 시간
    ///   - calculator: 주차 요금 계산기
    ///   - additionalFreeMinutes: 추가 무료 시간
    /// - Returns: 다음 요금 변경 시점, 더 이상 변경이 없으면 nil
    public static func nextChangeDate(
        startTime: Date,
        currentTime: Date,
        calculator: ParkingFeeCalculator,
        additionalFreeMinutes: Int = 0
    ) -> Date? {
        let totalFreeMinutes = calculator.freeMinutes + additionalFreeMinutes
        
        // 1. 무료 시간 종료 시점
        let freeEndTime = startTime.addingTimeInterval(TimeInterval(totalFreeMinutes * 60))
        if currentTime < freeEndTime {
            return freeEndTime
        }
        
        // 2. 기본 요금 시간 종료 시점
        let initialEndTime = freeEndTime.addingTimeInterval(TimeInterval(calculator.initialMinutes * 60))
        if currentTime < initialEndTime {
            return initialEndTime
        }
        
        // 3. 최대 요금 도달 시점 계산
        let maxCapTime = calculateMaxFeeReachTime(
            startTime: startTime,
            calculator: calculator,
            totalFreeMinutes: totalFreeMinutes
        )
        
        // 이미 최대 요금에 도달했다면 더 이상 변경 없음
        if let maxTime = maxCapTime, currentTime >= maxTime {
            return nil
        }
        
        // 4. 추가 요금 단위 경계 계산
        guard calculator.additionalMinutes > 0 else {
            // 추가 요금 단위가 0이면 더 이상 변경 없음
            return maxCapTime
        }
        
        let stepSeconds = TimeInterval(calculator.additionalMinutes * 60)
        let elapsedAfterInitial = currentTime.timeIntervalSince(initialEndTime)
        
        // 현재 위치에서 다음 경계까지의 시간 계산
        let currentStepNumber = Int(floor(elapsedAfterInitial / stepSeconds)) + 1
        let nextBoundary = initialEndTime.addingTimeInterval(TimeInterval(currentStepNumber) * stepSeconds)
        
        // 최대 요금 시점과 비교하여 더 이른 시점 반환
        if let maxTime = maxCapTime, nextBoundary > maxTime {
            return maxTime
        }
        
        return nextBoundary
    }
    
    /// 최대 요금에 도달하는 시점을 계산합니다
    /// - Parameters:
    ///   - startTime: 주차 시작 시간
    ///   - calculator: 주차 요금 계산기
    ///   - totalFreeMinutes: 총 무료 시간
    /// - Returns: 최대 요금 도달 시점, 최대 요금이 설정되지 않았으면 nil
    private static func calculateMaxFeeReachTime(
        startTime: Date,
        calculator: ParkingFeeCalculator,
        totalFreeMinutes: Int
    ) -> Date? {
        guard let maxFee = calculator.maxFee, calculator.additionalFee > 0 else {
            return nil
        }
        
        // 최대 요금이 기본 요금보다 작거나 같으면 기본 시간 종료 시점
        if maxFee <= calculator.initialFee {
            let freeEndTime = startTime.addingTimeInterval(TimeInterval(totalFreeMinutes * 60))
            return freeEndTime.addingTimeInterval(TimeInterval(calculator.initialMinutes * 60))
        }
        
        // 추가 요금으로 최대 요금에 도달하는 데 필요한 단위 수 계산
        let remainingFee = maxFee - calculator.initialFee
        let unitsToMax = Int(ceil(Double(remainingFee) / Double(calculator.additionalFee)))
        
        let freeEndTime = startTime.addingTimeInterval(TimeInterval(totalFreeMinutes * 60))
        let initialEndTime = freeEndTime.addingTimeInterval(TimeInterval(calculator.initialMinutes * 60))
        
        return initialEndTime.addingTimeInterval(TimeInterval(unitsToMax * calculator.additionalMinutes * 60))
    }
    
    /// 야간 요금 전환 시점들을 계산합니다
    /// - Parameters:
    ///   - startTime: 주차 시작 시간
    ///   - currentTime: 현재 시간
    ///   - calculator: 주차 요금 계산기
    /// - Returns: 다음 야간 요금 전환 시점들 (시작/종료)
    public static func nextNightRateChangeDate(
        startTime: Date,
        currentTime: Date,
        calculator: ParkingFeeCalculator
    ) -> Date? {
        guard calculator.hasNightRate,
              let startHour = calculator.nightStartHour,
              let endHour = calculator.nightEndHour else {
            return nil
        }
        
        let calendar = Calendar.current
        let currentDate = calendar.startOfDay(for: currentTime)
        
        // 오늘과 내일의 야간 시간 계산
        let dates = [currentDate, calendar.date(byAdding: .day, value: 1, to: currentDate)!]
        
        var upcomingTransitions: [Date] = []
        
        for date in dates {
            if let nightStart = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: date),
               let nightEnd = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: date) {
                
                if startHour <= endHour {
                    // 같은 날 내에서 야간 시간 (예: 22:00 ~ 06:00 다음날)
                    if nightStart > currentTime { upcomingTransitions.append(nightStart) }
                    if nightEnd > currentTime { upcomingTransitions.append(nightEnd) }
                } else {
                    // 자정을 넘는 야간 시간 (예: 22:00 ~ 06:00)
                    if nightStart > currentTime { upcomingTransitions.append(nightStart) }
                    
                    // 다음날 종료 시간도 고려
                    if let nextDayEnd = calendar.date(byAdding: .day, value: 1, to: nightEnd),
                       nextDayEnd > currentTime {
                        upcomingTransitions.append(nextDayEnd)
                    }
                }
            }
        }
        
        return upcomingTransitions.min()
    }
    
    /// 주어진 시간대의 요금 변경 스케줄을 생성합니다 (디버깅/모니터링용)
    /// - Parameters:
    ///   - startTime: 주차 시작 시간
    ///   - duration: 확인할 기간 (초)
    ///   - calculator: 주차 요금 계산기
    ///   - additionalFreeMinutes: 추가 무료 시간
    /// - Returns: 요금 변경 시점들의 배열
    public static func generateSchedule(
        startTime: Date,
        duration: TimeInterval,
        calculator: ParkingFeeCalculator,
        additionalFreeMinutes: Int = 0
    ) -> [Date] {
        var schedule: [Date] = []
        var currentTime = startTime
        let endTime = startTime.addingTimeInterval(duration)
        
        while currentTime < endTime {
            if let nextChange = nextChangeDate(
                startTime: startTime,
                currentTime: currentTime,
                calculator: calculator,
                additionalFreeMinutes: additionalFreeMinutes
            ) {
                if nextChange <= endTime {
                    schedule.append(nextChange)
                    currentTime = nextChange.addingTimeInterval(1) // 1초 후로 이동
                } else {
                    break
                }
            } else {
                break // 더 이상 변경 없음
            }
        }
        
        return schedule
    }
}

// MARK: - 편의 메서드
public extension FeeScheduler {
    
    /// 현재 시점에서 다음 요금 변경까지 남은 시간을 계산합니다
    /// - Parameters:
    ///   - startTime: 주차 시작 시간
    ///   - calculator: 주차 요금 계산기
    ///   - additionalFreeMinutes: 추가 무료 시간
    /// - Returns: 다음 변경까지 남은 시간 (초), 더 이상 변경이 없으면 nil
    static func timeUntilNextChange(
        startTime: Date,
        calculator: ParkingFeeCalculator,
        additionalFreeMinutes: Int = 0
    ) -> TimeInterval? {
        let currentTime = Date()
        guard let nextChange = nextChangeDate(
            startTime: startTime,
            currentTime: currentTime,
            calculator: calculator,
            additionalFreeMinutes: additionalFreeMinutes
        ) else {
            return nil
        }
        
        return max(0, nextChange.timeIntervalSince(currentTime))
    }
    
    /// 주어진 시간이 요금 변경 경계인지 확인합니다
    /// - Parameters:
    ///   - time: 확인할 시간
    ///   - startTime: 주차 시작 시간
    ///   - calculator: 주차 요금 계산기
    ///   - additionalFreeMinutes: 추가 무료 시간
    ///   - tolerance: 허용 오차 (초, 기본값: 1초)
    /// - Returns: 경계 시점이면 true
    static func isBoundaryTime(
        time: Date,
        startTime: Date,
        calculator: ParkingFeeCalculator,
        additionalFreeMinutes: Int = 0,
        tolerance: TimeInterval = 1.0
    ) -> Bool {
        // time 이전 시점에서 다음 변경 시점을 계산
        let checkTime = time.addingTimeInterval(-tolerance)
        
        guard let nextChange = nextChangeDate(
            startTime: startTime,
            currentTime: checkTime,
            calculator: calculator,
            additionalFreeMinutes: additionalFreeMinutes
        ) else {
            return false
        }
        
        return abs(nextChange.timeIntervalSince(time)) <= tolerance
    }
}