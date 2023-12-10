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

@main
struct GarageHassApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let garageSocketManager = GarageSocketManager(websocket: HassWebSocket.shared)
    let watchConnectivityHandler = WatchConnectivityHandler()
//    private lazy var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.yourdomain.GarageHassApp", category: "Network")

    init() {
//        setupWebSocketEventHandlers()
//        setupNotificationCenterObservers()
    }

    var body: some Scene {
        WindowGroup {
            PhoneView()
                .environmentObject(garageSocketManager)
                // .environmentObject(watchConnectivityHandler) // Uncomment if used
                //.onAppear(perform: setupNotificationCenterObservers)
                    .onChange(of: scenePhase) { newScenePhase in
                           switch newScenePhase {
                           case .active:
                               print("App is in active state.")
                               HassWebSocket.shared.connect(completion: { success in
                                   if success {
                                       print("Subscribing to events")
                                       HassWebSocket.shared.subscribeToEvents()
                                   }
                               })
                           case .background:
                               print("App is in background state in PhoneView.")
                               HassWebSocket.shared.disconnect()
                           case .inactive:
                               print("App is in inactive state.")
                           @unknown default:
                               print("Unknown scene phase.")
                           }
                       }
        }
    }

//    private func setupWebSocketEventHandlers() {
//        // WebSocket event handlers setup
//    }
//
//    private func setupNotificationCenterObservers() {
//        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
//            .sink { _ in
//                HassWebSocket.shared.attemptReconnection()
//                HassWebSocket.shared.updateConnectionStatus()
//                self.logger.debug("App became active, attempting WebSocket reconnection")
//            }
//            .store(in: &SubscriptionManager.cancellables)
//
//        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
//            .sink { _ in
//                HassWebSocket.shared.disconnect()
//                HassWebSocket.shared.updateConnectionStatus()
//                self.logger.debug("App is moving to the background, disconnecting WebSocket")
//            }
//            .store(in: &SubscriptionManager.cancellables)
//    }
}
