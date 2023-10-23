//
//  GarageViewModel.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-10-23.
//

import SwiftUI
import Foundation
import HassFramework
import Combine

class GarageViewModel: ObservableObject {
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = false
    @Published var alarmOff: Bool = true
    @Published var connectionState: ConnectionState = .disconnected  // Assuming WebSocketConnectionState is an enum or type that describes the connection state
    var connectionStateBinding: Binding<ConnectionState> {
        Binding(
            get: { self.connectionState },
            set: { self.connectionState = $0 }
        )
    }
    private var websocket: HassWebSocket
    private var cancellables = Set<AnyCancellable>() // 1. Create a Cancellable set

    
    init(websocket: HassWebSocket = WebSocketManager.shared.websocket) {
        self.websocket = websocket
        setupWebSocketEvents()
        
        // Update connectionState based on websocket's state
          self.connectionState = websocket.connectionState  // Assuming websocket has a connectionState property
    }

    // Setup WebSocket event handlers
    private func setupWebSocketEvents() {
          websocket.onEventReceived = { [weak self] event in
              self?.handleWebSocketEvent(event: event)
          }
          
          // 2. Subscribe to changes in websocket's connectionState
          websocket.$connectionState
              .sink { [weak self] newState in
                  self?.connectionState = newState
              }
              .store(in: &cancellables)
      }
    
    // Handle WebSocket events
    private func handleWebSocketEvent(event: String) {
        guard let data = event.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let message = jsonObject as? [String: Any],
              let eventType = message["event_type"] as? String, eventType == "state_changed",
              let eventData = message["data"] as? [String: Any],
              let entityId = eventData["entity_id"] as? String,
              entityId == "binary_sensor.newgarage_left_door_sensor",
              let newStateData = eventData["new_state"] as? [String: Any],
              let newState = newStateData["state"] as? String
        else { return }
        
        DispatchQueue.main.async {
            self.leftDoorClosed = (newState == "closed")
        }
    }
    
    // Toggle door action
    func handleDoorAction(entityId: String) {
        if websocket.isConnected() {
            websocket.setEntityState(entityId: entityId, newState: "toggle")
        } else {
            websocket.connect { success in
                if success {
                    self.websocket.setEntityState(entityId: entityId, newState: "toggle")
                } else {
                    print("Failed to reconnect to WebSocket.")
                }
            }
        }
    }
}
extension GarageViewModel {
    func establishConnectionIfNeeded() {
        if !websocket.isConnected() {
            websocket.connect { success in
                if success {
                    print("Successfully connected!")
                } else {
                    print("Failed to connect to WebSocket.")
                }
            }
        }
    }
}

