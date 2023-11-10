import SwiftUI
import Foundation
import HassFramework  // Import the necessary frameworks.
import Combine  // Import Combine for handling event streams and data binding.

// ViewModel for a Garage interface in a SwiftUI application.
class GarageViewModel: ObservableObject {
    // Published properties will cause views to update when their values change.
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var connectionState: ConnectionState = .disconnected

    // Provide a binding to connectionState for SwiftUI views to react to changes.
    var connectionStateBinding: Binding<ConnectionState> {
        Binding(
            get: { self.connectionState },
            set: { self.connectionState = $0 }
        )
    }
    
    // WebSocket used for communicating with Home Assistant.
    private var websocket: HassWebSocket
    // Set of cancellable objects to store Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // Initialize with a default WebSocket connection.
    init(websocket: HassWebSocket = WebSocketManager.shared.websocket) {
        self.websocket = websocket
        setupWebSocketEvents()
        self.connectionState = websocket.connectionState
    }
    
    // Setup WebSocket event handlers and subscriptions.
    private func setupWebSocketEvents() {
        print("Setting up WebSocket events.")
        // When an event is received from the WebSocket, handle it.
        websocket.onEventReceived = { [weak self] event in
            self?.handleWebSocketEvent(event: event)
        }
        // Register self as an event message handler.
        websocket.addEventMessageHandler(self)
        // Subscribe to connectionState changes of the WebSocket.
        websocket.$connectionState
            .sink { [weak self] newState in
                self?.connectionState = newState
            }
            .store(in: &cancellables)
    }
    
    // Handle events received through the WebSocket.
    private func handleWebSocketEvent(event: String) {
        // Process the event string into a JSON object.
        guard let data = event.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let message = jsonObject as? [String: Any],
              let eventType = message["event_type"] as? String, eventType == "state_changed",
              let eventData = message["data"] as? [String: Any],
              let newStateData = eventData["new_state"] as? [String: Any],
              let newState = newStateData["state"] as? String,
              let entityId = eventData["entity_id"] as? String
        else { return }
        
        // Update UI elements based on the new state of the entity.
        processStateChange(entityId: entityId, newState: newState)
    }
    
    // Update the state of the doors and alarm based on entity ID and new state.
    private func processStateChange(entityId: String, newState: String) {
        DispatchQueue.main.async {
            switch entityId {
            case "binary_sensor.left_door_sensor":
                // Update the state of the left door sensor.
                self.leftDoorClosed = (newState == "off") // Assuming "off" means closed
            case "binary_sensor.right_door_sensor":
                // Update the state of the right door sensor.
                self.rightDoorClosed = (newState == "off") // Assuming "off" means closed
            case "binary_sensor.alarm_sensor":
                // Update the state of the alarm sensor.
                self.alarmOff = (newState == "off") // Assuming "off" means the alarm is not triggered
            default:
                // Handle unknown sensor entities.
                print("Received state change for unknown sensor: \(entityId)")
            }
        }
    }
    
    // Handle actions on entities such as doors and alarms.
    func handleEntityAction(entityId: String, requiresConfirmation: Bool = false, newState: String? = nil) {
        let action = {
            // Define the state to set (on, off, toggle).
            let stateToSet = newState ?? "toggle"
            // If WebSocket is connected, set the entity state.
            if self.websocket.isConnected() {
                self.websocket.setEntityState(entityId: entityId, newState: stateToSet)
            } else {
                // Attempt to connect to the WebSocket if not already connected.
                self.websocket.connect { success in
                    if success {
                        self.websocket.setEntityState(entityId: entityId, newState: stateToSet)
                    } else {
                        print("Failed to reconnect to WebSocket.")
                    }
                }
            }
        }
        
        // If confirmation is required, show a dialog before executing the action.
        if requiresConfirmation {
            // Confirmation handling would be implemented in the SwiftUI views.
        } else {
            action()
        }
    }
    
    // Specific function to handle the confirmed action for toggling the alarm.
    func handleAlarmToggleConfirmed() {
        handleEntityAction(entityId: "binary_sensor.alarm_sensor", requiresConfirmation: true)
    }
    
    // Execute the action when the alarm state confirmation is received.
    func handleAlarmActionConfirmed() {
        // Determine which entity ID to toggle based on the current state of the alarm.
        let entityIdToToggle = self.alarmOff ? "switch.alarm_on" : "switch.alarm_off"
        triggerSwitch(entityId: entityIdToToggle)
    }

    // Helper method to briefly trigger a switch for a short period of time.
    private func triggerSwitch(entityId: String) {
        if self.websocket.isConnected() {
            // Send a command to toggle the entity's state.
            self.websocket.setEntityState(entityId: entityId, newState: "toggle")
            // After a delay, send another command to toggle it back, simulating a button press.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.websocket.setEntityState(entityId: entityId, newState: "toggle")
            }
        } else {
            // Attempt to reconnect if not connected.
            self.websocket.connect { success in
                if success {
                    // If the connection is successful, trigger the switch.
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
}

// Extension of the ViewModel to manage WebSocket connection.
extension GarageViewModel {
    // Establish a WebSocket connection if it's not already connected.
    func establishConnectionIfNeeded() {
        print("Checking and establishing a WebSocket connection if needed.")
        if !websocket.isConnected() {
            websocket.connect { success in
                if success {
                    // Upon successful connection, subscribe to events.
                    self.websocket.subscribeToEvents()
                } else {
                    print("Failed to connect to WebSocket.")
                }
            }
        }
    }
}

// Extension for conforming to the EventMessageHandler protocol.
extension GarageViewModel: EventMessageHandler {
    // Handle event messages received from the WebSocket.
    func handleEventMessage(_ message: HAEventData) {
        // Process the new state from the event data message.
        guard let newState = message.new_state?.state else {
            return
        }
        processStateChange(entityId: message.entity_id, newState: newState)
    }
}
