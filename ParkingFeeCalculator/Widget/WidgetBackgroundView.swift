//
//  WidgetBackgroundView.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import SwiftUI

struct WidgetBackgroundView: View {
    var body: some View {
        Color(.systemBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

