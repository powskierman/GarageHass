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
    let garageSocketManager = GarageSocketManager.shared // Ensure this instance is created

    init() {
        watchConnectivityHandler.stateDelegate = self
        print("GarageHassApp initialized")
    }

    var body: some Scene {
        WindowGroup {
            PhoneView()
                .environmentObject(watchConnectivityHandler)
                .environmentObject(garageSocketManager)
                .onChange(of: scenePhase) { newScenePhase in
                    print("Scene phase changed: \(newScenePhase)")
                    switch newScenePhase {
                    case .active:
                        watchConnectivityHandler.appDidBecomeActive()
                    case .background:
                        watchConnectivityHandler.appDidEnterBackground()
                    default:
                        break
                    }
                }
        }
    }
}

extension GarageHassApp: AppStateUpdateDelegate {
    func appDidBecomeActive() {
        print("App is now active - Reconnecting WebSocket and subscribing to events")
        // Logic for app becoming active
        HassWebSocket.shared.connect { success in
            if success {
                print("WebSocket successfully reconnected")
                HassWebSocket.shared.subscribeToEvents()
            } else {
                print("Failed to reconnect WebSocket")
            }
        }
    }

    func appDidEnterBackground() {
        print("App is now in background - Disconnecting WebSocket")
        // Logic for app entering background
        HassWebSocket.shared.disconnect()
    }
}

