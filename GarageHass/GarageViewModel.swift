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
        print("At processStateChange")
        DispatchQueue.main.async {
            if entityId == "binary_sensor.left_door_sensor" {
                self.leftDoorClosed = (newState == "off") // Assuming "off" means closed
            } else if entityId == "binary_sensor.right_door_sensor" {
                self.rightDoorClosed = (newState == "off") // Assuming "off" means closed
            }
        }
    }

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
