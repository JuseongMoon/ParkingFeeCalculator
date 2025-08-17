//
//  ParkingFeeWidgetView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import SwiftUI
import WidgetKit

struct ParkingFeeWidgetView: View {
    let data: SharedParkingData
    
    var body: some View {
        Group {
            if data.isParkingActive {
                VStack(spacing: 4) {
                    Text("주차비")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(data.currentFee)원")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("주차 대기중")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

