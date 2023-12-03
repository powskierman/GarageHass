//
//  GarageSocketManager.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-25.
//

import Foundation
import Combine
import HassFramework
import Starscream

class GarageSocketManager: ObservableObject, EventMessageHandler, HassWebSocketDelegate {

    static let shared = GarageSocketManager(websocket: HassWebSocket.shared)

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
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        print("WebSocket event received: \(event)")

        switch event {
        case .connected(let headers):
            print("WebSocket connected with headers: \(headers)")
            // Handle connection established logic here
            self.websocket.connectionState = .connected

        case .disconnected(let reason, let code):
            print("WebSocket disconnected with reason: \(reason), code: \(code)")
            // Handle disconnection logic here
            self.websocket.connectionState = .disconnected

        case .text(let text):
            print("Received text: \(text)")
            // Handle text message received logic here
            // This might involve parsing JSON data, handling specific events, etc.

        // Handle other cases like .binary, .ping, .pong, etc. as needed
        // ...

        default:
            break
        }
    }
    
    
    func connectSendCommand(command: String, completion: @escaping (Bool) -> Void) {
        establishConnectionIfNeeded { [weak self] isConnected in
            guard isConnected else {
                print("Failed to establish WebSocket connection.")
                completion(false)
                return
            }

            if let strongSelf = self {
                if strongSelf.websocket.isAuthenticated {
                    strongSelf.websocket.sendTextMessage(command)
                    completion(true)
                } else {
                    print("Authentication failed or not completed.")
                    completion(false)
                }
            } else {
                print("Self is nil, cannot proceed.")
                completion(false)
            }
        }
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

        websocket.connect { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.websocket.subscribeToEvents()
                    self?.error = nil
                    completion(true)
                } else {
                    self?.error = NSError(domain: "WebSocket", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to establish WebSocket connection."])
                    completion(false)
                }
            }
        }
    }

    func forceReconnect() {
        if isConnected() {
            disconnect()
        }
        establishConnectionIfNeeded()
    }
    
    
     // Handles actions on entities.
    func handleEntityAction(entityId: String, newState: String? = nil) {
        let service = newState ?? "toggle"
        let messageId = websocket.getNextMessageId() // Get next message ID

        let serviceData: [String: Any] = ["entity_id": entityId]
        let callServiceMessage: [String: Any] = [
            "id": messageId,
            "type": "call_service",
            "domain": "switch",
            "service": service,
            "service_data": serviceData
        ]

        // Serialize to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: callServiceMessage, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            connectSendCommand(command: jsonString) { success in
                if success {
                    print("Command for \(entityId) sent successfully.")
                } else {
                    print("Failed to send command for \(entityId).")
                }
            }
        } else {
            print("Failed to serialize command.")
        }
    }

    // Helper method to send entity action.
    private func sendEntityAction(entityId: String, newState: String?) {
        let stateToSet = newState ?? "toggle"
        self.websocket.setEntityState(entityId: entityId, newState: stateToSet)
    }
    
    // Implement didReceiveText from HassWebSocketDelegate
      func didReceiveText(_ text: String, from websocket: HassWebSocket) {
          guard let data = text.data(using: .utf8) else {
              print("Error converting text to Data")
              return
          }

          do {
              let eventData = try JSONDecoder().decode(HAEventData.self, from: data)
              handleEventMessage(eventData)
          } catch {
              print("Error decoding HAEventData: \(error)")
          }
      }
}


extension GarageSocketManager {
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

