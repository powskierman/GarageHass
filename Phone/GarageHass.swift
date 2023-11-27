//
//  GarageHassApp.swift
//  GarageNew
//
//  Created by Michel Lapointe on 2022-10-22.
//

import SwiftUI
import HassFramework

@main
struct GarageHassApp: App {
    // Initialize WebSocketManager
    let webSocketManager = WebSocketManager(websocket: HassWebSocket())

    // Initialize WatchConnectivityHandler if needed
     let watchConnectivityHandler = WatchConnectivityHandler()

    var body: some Scene {
        WindowGroup {
            PhoneView()
                .environmentObject(webSocketManager)
                // If you use WatchConnectivityHandler, provide it as an environment object as well
                // .environmentObject(watchConnectivityHandler)
        }
    }
}
