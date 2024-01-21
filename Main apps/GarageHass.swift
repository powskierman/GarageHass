//
//  GarageHassApp.swift
//  GarageNew
//
//  Created by Michel Lapointe on 2022-10-22.
//

import SwiftUI
import HassFramework
import Combine
import os
import SwiftUI

@main
struct GarageHassApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let watchConnectivityHandler = WatchConnectivityHandler()
//    let garageSocketManager = GarageSocketManager.shared // Ensure this instance is created

    init() {
        watchConnectivityHandler.stateDelegate = self
        // print("GarageHassApp initialized")
    }

    var body: some Scene {
        WindowGroup {
            PhoneView()
                .environmentObject(watchConnectivityHandler)
//                .environmentObject(garageSocketManager)
                .environmentObject(GarageRestManager.shared)
                .onChange(of: scenePhase) {
                    // Your existing switch statement
                    switch scenePhase {
                    case .active:
                        watchConnectivityHandler.isAppActive = true
                        appDidBecomeActive()
                    case .inactive:
                        watchConnectivityHandler.isAppActive = false
                        appDidEnterBackground()
                    case .background:
                        appDidEnterBackground()
                    default:
                        break
                    }
                }
        }
    }
}

extension GarageHassApp: AppStateUpdateDelegate {
    func appDidBecomeActive() {
        print("App is now active - Refreshing data from RESTful API")
        // Logic for refreshing data using RESTful API
//        GarageRestManager.shared.refreshData { success in
//            if success {
//                print("Data successfully refreshed from RESTful API")
//            } else {
//                print("Failed to refresh data from RESTful API")
//            }
//        }
    }

    func appDidEnterBackground() {
        print("App is now in background")
        // Any necessary clean-up for REST API
        // For example, cancelling ongoing requests
//        GarageRestManager.shared.cancelOngoingRequests()
    }
}


