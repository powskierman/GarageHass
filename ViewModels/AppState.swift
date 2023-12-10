//
//  AppState.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-12-09.
//

import Foundation
import Combine
import os

class AppState: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    let logger = Logger(subsystem: "com.yourdomain.yourapp", category: "Network")
}

class SubscriptionManager {
    static var cancellables = Set<AnyCancellable>()
}
