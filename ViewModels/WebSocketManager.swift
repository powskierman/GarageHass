//
//  WebSocketManager.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-25.
//

import Foundation
import Combine
import HassFramework

class WebSocketManager: ObservableObject, EventMessageHandler {

    static let shared = WebSocketManager(websocket: HassWebSocket())

    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var connectionState: ConnectionState = .disconnected
    @Published var error: Error?
    @Published var hasErrorOccurred: Bool = false
    
    var websocket: HassWebSocket
    private var cancellables = Set<AnyCancellable>()
    var onStateChange: ((String, String) -> Void)?

    init(websocket: HassWebSocket) {
        self.websocket = websocket
        print("WebSocketManager initialized")
        self.websocket.addEventMessageHandler(self)  // Register as event message handler
        print("WebSocketManager registered as EventMessageHandler")
        setupWebSocketEvents()
    }
    
    private func setupWebSocketEvents() {
        print("Setting up WebSocket events")
        websocket.onEventReceived = { [weak self] event in
            print("WebSocket event received: \(event)")
            self?.handleWebSocketEvent(event: event)
        }
        websocket.$connectionState
            .sink { [weak self] newState in
                print("Connection state changed to: \(newState)")
                self?.connectionState = newState
            }
            .store(in: &cancellables)
    }

    private func handleWebSocketEvent(event: String) {
        print("Handling WebSocket event: \(event)")
        guard let data = event.data(using: .utf8) else {
            print("Error converting event string to Data")
            return
        }

        do {
            let eventData = try JSONDecoder().decode(HassFramework.HAEventData.self, from: data)
            handleEventMessage(eventData)
        } catch {
            print("Error decoding HAEventData: \(error)")
        }
    }

//    private func handleEventMessage(_ message: HassFramework.HAEventData) {
//        guard let newState = message.data.newState.state,
//              let entityId = message.data.entityId else {
//            print("Error accessing state change data")
//            return
//        }
//        print("State change detected: Entity ID \(entityId), New State: \(newState)")
//        processStateChange(entityId: entityId, newState: newState)
//    }


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
             if (entityId == "binary_sensor.left_door_sensor" && previousState != self.leftDoorClosed) ||
                (entityId == "binary_sensor.right_door_sensor" && previousState != self.rightDoorClosed) ||
                (entityId == "binary_sensor.alarm_sensor" && previousState != self.alarmOff) {
                 print("State changed for \(entityId), calling onStateChange")
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
                DispatchQueue.main.async {
                    if success {
                        self.websocket.subscribeToEvents()
                        self.error = nil
                    } else {
                        self.error = NSError(domain: "WebSocket", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to establish WebSocket connection."])
                    }
                    completion(success)
                }
            }
        }


     // Handles actions on entities.
    func handleEntityAction(entityId: String, newState: String? = nil) {
        // First, check if the WebSocket connection is active.
        if !websocket.isConnected() {
            // If the connection is not active, try to re-establish it.
            establishConnectionIfNeeded { [weak self] success in
                if success {
                    // If the connection is successfully re-established, proceed with the action.
                    self?.sendEntityAction(entityId: entityId, newState: newState)
                } else {
                    // Handle the case where the connection could not be re-established.
                    print("Failed to reconnect to WebSocket.")
                }
            }
        } else {
            // If the connection is already active, proceed with the action.
            sendEntityAction(entityId: entityId, newState: newState)
        }
    }

    // Helper method to send entity action.
    private func sendEntityAction(entityId: String, newState: String?) {
        let stateToSet = newState ?? "toggle"
        self.websocket.setEntityState(entityId: entityId, newState: stateToSet)
    }
}

extension WebSocketManager {
    public func handleEventMessage(_ message: HassFramework.HAEventData) {
        print("At handleEventMessage!")

        // Try to convert HAEventData to JSON
        guard let messageData = try? JSONEncoder().encode(message),
              let messageJSON = try? JSONSerialization.jsonObject(with: messageData, options: []) as? [String: Any],
              let eventData = messageJSON["data"] as? [String: Any],
              let entityId = eventData["entity_id"] as? String,
              let newStateData = eventData["new_state"] as? [String: Any],
              let newState = newStateData["state"] as? String else {
            print("Error parsing HAEventData")
            return
        }

        print("Received event message - Entity ID: \(entityId), New State: \(newState)")
        processStateChange(entityId: entityId, newState: newState)
    }
}

