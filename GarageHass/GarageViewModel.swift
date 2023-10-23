//
//  GarageViewModel.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-10-23.
//

import Foundation
import HassFramework

class GarageViewModel: ObservableObject {
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    
    private var websocket: HassWebSocket
    
    init(websocket: HassWebSocket = WebSocketManager.shared.websocket) {
        self.websocket = websocket
        setupWebSocketEvents()
    }

    // Setup WebSocket event handlers
    private func setupWebSocketEvents() {
        websocket.onEventReceived = { [weak self] event in
            self?.handleWebSocketEvent(event: event)
        }
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

