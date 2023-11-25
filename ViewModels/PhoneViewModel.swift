import SwiftUI
import Foundation
import Combine
import HassFramework

class PhoneViewModel: ObservableObject {
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var connectionState: ConnectionState = .disconnected

    private var websocket: HassWebSocket
    private var cancellables = Set<AnyCancellable>()
    private var entityStateSubscription: AnyCancellable?  // Ensure this is declared

    init(websocket: HassWebSocket) {
        print("PhoneViewModel: Initializing...")
        self.websocket = websocket
        
        setupWebSocketEvents()
        self.connectionState = websocket.connectionState

        subscribeToEntityStateChanges()
    }
    
    private func setupWebSocketEvents() {
        print("PhoneViewModel: Setting up WebSocket events...")
        websocket.onEventReceived = { [weak self] event in
            print("PhoneViewModel: WebSocket event received: \(event)")
            self?.handleWebSocketEvent(event: event)
        }
        websocket.addEventMessageHandler(self)
        websocket.$connectionState
            .sink { [weak self] newState in
                print("PhoneViewModel: WebSocket connection state changed: \(newState)")
                self?.connectionState = newState
            }
            .store(in: &cancellables)
    }

    private func handleWebSocketEvent(event: String) {
        print("PhoneViewModel: Handling WebSocket event: \(event)")
        guard let data = event.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let message = jsonObject as? [String: Any],
              let eventType = message["event_type"] as? String, eventType == "state_changed",
              let eventData = message["data"] as? [String: Any],
              let newStateData = eventData["new_state"] as? [String: Any],
              let newState = newStateData["state"] as? String,
              let entityId = eventData["entity_id"] as? String
        else {
            print("PhoneViewModel: Unable to parse WebSocket event")
            return
        }

        processStateChange(entityId: entityId, newState: newState)
    }

    private func subscribeToEntityStateChanges() {
        print("PhoneViewModel: Subscribing to entity state changes")
        if let appDelegate = AppDelegate.shared {
            entityStateSubscription = appDelegate.entityStateSubject
                .sink { [weak self] change in
                    print("PhoneViewModel: Received entity state change: \(change)")
   //                 self?.processStateChange(entityId: change.entityId, newState: change.newState)
                    self?.handleEntityAction(entityId: change.entityId, newState: change.newState)
        
                }
        } else {
            print("PhoneViewModel: Error - AppDelegate shared instance is not available.")
        }
    }
    
    private func processStateChange(entityId: String, newState: String) {
        print("PhoneViewModel: Processing state change - Entity ID: \(entityId), New State: \(newState)")
        DispatchQueue.main.async {
            switch entityId {
            case "binary_sensor.left_door_sensor":
                self.leftDoorClosed = (newState == "off")
            case "binary_sensor.right_door_sensor":
                self.rightDoorClosed = (newState == "off")
            case "binary_sensor.alarm_sensor":
                self.alarmOff = (newState == "off")
            default:
                print("PhoneViewModel: Received state change for unknown sensor: \(entityId)")
            }
        }
    }
    func handleEntityAction(entityId: String, requiresConfirmation: Bool = false, newState: String? = nil) {
        let action = {
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
            // Confirmation handling logic here
        } else {
            action()
        }
    }

    func handleAlarmToggleConfirmed() {
        handleEntityAction(entityId: "binary_sensor.alarm_sensor", requiresConfirmation: true)
    }
    
    func handleAlarmActionConfirmed() {
        let entityIdToToggle = self.alarmOff ? "switch.alarm_on" : "switch.alarm_off"
        triggerSwitch(entityId: entityIdToToggle)
    }

    private func triggerSwitch(entityId: String) {
        if self.websocket.isConnected() {
            self.websocket.setEntityState(entityId: entityId, newState: "toggle")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.websocket.setEntityState(entityId: entityId, newState: "toggle")
            }
        } else {
            self.websocket.connect { success in
                if success {
                    self.websocket.setEntityState(entityId: entityId, newState: "on")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.websocket.setEntityState(entityId: entityId, newState: "off")
                    }
                } else {
                    print("Failed to reconnect to WebSocket.")
                }
            }
        }
    }

    func establishConnectionIfNeeded() {
        print("Checking and establishing a WebSocket connection if needed.")
        if !websocket.isConnected() {
            websocket.connect { success in
                if success {
                    self.websocket.subscribeToEvents()
                } else {
                    print("Failed to connect to WebSocket.")
                }
            }
        }
    }
}

extension PhoneViewModel: EventMessageHandler {
    func handleEventMessage(_ message: HAEventData) {
        guard let newState = message.new_state?.state else {
            return
        }
        processStateChange(entityId: message.entity_id, newState: newState)
    }
}
