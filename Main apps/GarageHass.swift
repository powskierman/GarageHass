//
//  GarageHassApp.swift
//  GarageNew
//
//  Created by Michel Lapointe on 2022-10-22.
//

import SwiftUI
import HassFramework
import Combine

@main
struct GarageHassApp: App {
    // Initialize WebSocketManager
    let garageSocketManager = GarageSocketManager(websocket: HassWebSocket())
    var cancellables = Set<AnyCancellable>()
    
    // Initialize WatchConnectivityHandler if needed
     let watchConnectivityHandler = WatchConnectivityHandler()
    
    init() {
         // Listen for the app becoming active and call attemptReconnection
         NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
             .sink { [weak self] _ in
                 self?.webSocketManager.attemptReconnection()
             }
             .store(in: &cancellables)
     }


    var body: some Scene {
        WindowGroup {
            PhoneView()
                .environmentObject(garageSocketManager)
                // If you use WatchConnectivityHandler, provide it as an environment object as well
                // .environmentObject(watchConnectivityHandler)
        }
    }
}
