//
//  WebSocketManager.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-25.
//

import Foundation
import Combine
import HassFramework

class WebSocketManager: ObservableObject {

    static let shared = WebSocketManager(websocket: HassWebSocket())

    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var connectionState: ConnectionState = .disconnected

    var websocket: HassWebSocket
    private var cancellables = Set<AnyCancellable>()
    var onStateChange: ((String, String) -> Void)?

    init(websocket: HassWebSocket) {
        self.websocket = websocket
        setupWebSocketEvents()
        self.connectionState = websocket.connectionState
    }
    
    private func setupWebSocketEvents() {
        websocket.onEventReceived = { [weak self] event in
            self?.handleWebSocketEvent(event: event)
        }
        websocket.addEventMessageHandler(self)
        websocket.$connectionState
            .sink { [weak self] newState in
                self?.connectionState = newState
            }
            .store(in: &cancellables)
    }

    private func handleWebSocketEvent(event: String) {
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
         print("Processing state change - Entity ID: \(entityId), New State: \(newState)")
         DispatchQueue.main.async {
             let previousState: Bool
             switch entityId {
             case "binary_sensor.left_door_sensor":
                 previousState = self.leftDoorClosed
                 self.leftDoorClosed = (newState == "off")
             case "binary_sensor.right_door_sensor":
                 previousState = self.rightDoorClosed
                 self.rightDoorClosed = (newState == "off")
             case "binary_sensor.alarm_sensor":
                 previousState = self.alarmOff
                 self.alarmOff = (newState == "off")
             default:
                 print("Unknown sensor: \(entityId)")
                 return
             }
             // Notify if the state changed
             if (entityId == "binary_sensor.left_door_sensor" && previousState != self.leftDoorClosed) ||
                (entityId == "binary_sensor.right_door_sensor" && previousState != self.rightDoorClosed) ||
                (entityId == "binary_sensor.alarm_sensor" && previousState != self.alarmOff) {
                 self.onStateChange?(entityId, newState)
             }
         }
     }
 
    // This function establishes a WebSocket connection if not already connected.
     func establishConnectionIfNeeded(completion: @escaping (Bool) -> Void = { _ in }) {
         guard !websocket.isConnected() else {
             completion(true)
             return
         }

         websocket.connect { success in
             if success {
                 self.websocket.subscribeToEvents()
             }
             completion(success)
         }
     }

     // Handles actions on entities.
     func handleEntityAction(entityId: String, newState: String? = nil) {
         let stateToSet = newState ?? "toggle"
         establishConnectionIfNeeded { success in
             if success {
                 self.websocket.setEntityState(entityId: entityId, newState: stateToSet)
             } else {
                 print("Failed to reconnect to WebSocket.")
             }
         }
     }
}

extension WebSocketManager: EventMessageHandler {
    func handleEventMessage(_ message: HAEventData) {
        guard let newState = message.new_state?.state else {
            return
        }
        processStateChange(entityId: message.entity_id, newState: newState)
    }
}

