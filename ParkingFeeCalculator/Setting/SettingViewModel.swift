//
//  SettingViewModel.swift
//  ParkingFeeCalculator
//
//  Created by 문주성 on 8/17/25.
//

import Foundation
import SwiftUI

class SettingViewModel: ObservableObject {
    @AppStorage("isParkingFeeAlertEnabled") var isParkingFeeAlertEnabled: Bool = false
    @AppStorage("parkingFeeAlertThreshold") var parkingFeeAlertThreshold: Int = 50000
}

