//
//  TimeInterval+Formatting.swift
//  ParkingFeeCore
//
//  Created by 문주성 on 8/24/25.
//

import Foundation

// MARK: - TimeInterval 확장 (시간 포맷팅)
public extension TimeInterval {
    /// 경과 시간을 한국어 형식으로 포맷합니다 (예: "1시간 30분")
    var koreanTimeFormat: String {
        let minutes = Int(self / 60)
        
        if minutes < 1 {
            return "1분 미만"
        } else if minutes < 60 {
            return "\(minutes)분"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)시간"
            } else {
                return "\(hours)시간 \(remainingMinutes)분"
            }
        }
    }
    
    /// 경과 시간을 시:분:초 형식으로 포맷합니다 (예: "01:30:45")
    var timeFormat: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// 경과 시간을 Navigation 스타일로 포맷합니다 (위젯용)
    var navigationTimeFormat: String {
        let minutes = Int(self / 60)
        
        if minutes < 1 {
            return "1분 미만"
        } else if minutes < 60 {
            return "\(minutes)분"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)시간"
            } else {
                return "\(hours)시간 \(remainingMinutes)분"
            }
        }
    }
}

// MARK: - Date 확장 (주차 관련)
public extension Date {
    /// 주차 시작 시간을 한국어 형식으로 포맷합니다 (예: "오후 2:30")
    var parkingStartTimeFormat: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: self)
    }
    
    /// 주차 시작 시간을 시:분 형식으로 포맷합니다 (예: "14:30")
    var timeOnlyFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// 완전한 한국어 날짜시간 형식 (예: "2023년 8월 24일 오후 2:30")
    var koreanDateTimeFormat: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일 a h:mm"
        return formatter.string(from: self)
    }
}