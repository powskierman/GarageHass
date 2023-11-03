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
    @Published var connectionState: ConnectionState = .disconnected
    var connectionStateBinding: Binding<ConnectionState> {
        Binding(
            get: { self.connectionState },
            set: { self.connectionState = $0 }
        )
    }
    
    private var websocket: HassWebSocket
    private var cancellables = Set<AnyCancellable>()
    
    init(websocket: HassWebSocket = WebSocketManager.shared.websocket) {
        self.websocket = websocket
        setupWebSocketEvents()
        self.connectionState = websocket.connectionState
    }
    
    private func setupWebSocketEvents() {
        print("At setupWebSocketEvents")
        websocket.onEventReceived = { [weak self] event in
            self?.handleWebSocketEvent(event: event)
        }
        websocket.addEventMessageHandler(self)
        print("I'm at websocket.addEventMessageHandler")
        websocket.$connectionState
            .sink { [weak self] newState in
                self?.connectionState = newState
            }
            .store(in: &cancellables)
    }
    
    private func handleWebSocketEvent(event: String) {
        print("At handleWebSocketEvent")
        guard let data = event.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let message = jsonObject as? [String: Any],
              let eventType = message["event_type"] as? String, eventType == "state_changed",
              let eventData = message["data"] as? [String: Any],
              let newStateData = eventData["new_state"] as? [String: Any],
              let newState = newStateData["state"] as? String,
              let entityId = eventData["entity_id"] as? String
        else { return }
        
        processStateChange(entityId: entityId, newState: newState)
    }
    
    private func processStateChange(entityId: String, newState: String) {
        print("At processStateChange for entityId: \(entityId) with newState: \(newState)")
        DispatchQueue.main.async {
            switch entityId {
            case "binary_sensor.left_door_sensor":
                self.leftDoorClosed = (newState == "off") // Assuming "off" means closed
            case "binary_sensor.right_door_sensor":
                self.rightDoorClosed = (newState == "off") // Assuming "off" means closed
            case "binary_sensor.alarm_sensor":
                self.alarmOff = (newState == "off") // Assuming "off" means alarm is not triggered
            default:
                print("Received state change for unknown sensor: \(entityId)")
            }
        }
    }
    
    func handleEntityAction(entityId: String, requiresConfirmation: Bool = false, newState: String? = nil) {
        let action = {
            // If newState is provided, use it, otherwise toggle
            let stateToSet = newState ?? "toggle"
            if self.websocket.isConnected() {
                self.websocket.setEntityState(entityId: entityId, newState: stateToSet)
            } else {
                self.websocket.connect { success in
                    if success {
                        self.websocket.setEntityState(entityId: entityId, newState: stateToSet)
                    } else {
                        print("Failed to reconnect to WebSocket.")
                    }
                }
            }
        }
        
        if requiresConfirmation {
            // Show confirmation dialog to the user and proceed if confirmed
            // The actual implementation of the confirmation dialog depends on the UI framework being used
            // For SwiftUI, this could involve a State variable to trigger an alert
        } else {
            action()
        }
    }
    
    // This function should only be called after user confirmation to toggle the alarm state
    func handleAlarmToggleConfirmed() {
        handleEntityAction(entityId: "binary_sensor.alarm_sensor", requiresConfirmation: true)
    }
}

extension GarageViewModel {
    func establishConnectionIfNeeded() {
        print("I'm at establishConnectionIfNeeded")
        if !websocket.isConnected() {
            websocket.connect { success in
                if success {
                    print("Successfully connected!")
                    self.websocket.subscribeToEvents()
                    print("I'm at self.websocket.subscribeToEvents")
                } else {
                    print("Failed to connect to WebSocket.")
                }
            }
        }
    }
}

extension GarageViewModel: EventMessageHandler {
    func handleEventMessage(_ message: HAEventData) {
        print("I'm at handleEventMessage")
        guard let newState = message.new_state?.state else {
            return
        }
        processStateChange(entityId: message.entity_id, newState: newState)
    }
}
