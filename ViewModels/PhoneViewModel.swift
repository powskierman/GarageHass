import SwiftUI
import Foundation
import Combine
import HassFramework
import WatchConnectivity

class PhoneViewModel: NSObject, ObservableObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var connectionState: ConnectionState = .disconnected
    
    private var websocket: HassWebSocket
    private var cancellables = Set<AnyCancellable>()
    
    // Watch Connectivity properties
    var session: WCSession
    
    override init() {
        print("Initializing GarageViewModel...")
        self.websocket = WebSocketManager.shared.websocket
        self.session = WCSession.default
        
        super.init()
        
        setupWebSocketEvents()
        self.connectionState = websocket.connectionState
        
        // Setup WCSession
        if WCSession.isSupported() {
            print("WCSession is supported. Setting delegate and activating...")
            self.session.delegate = self
            self.session.activate()
        } else {
            print("WCSession is not supported on this device.")
        }
    }
    
    var connectionStateBinding: Binding<ConnectionState> {
        Binding(
            get: { self.connectionState },
            set: { self.connectionState = $0 }
        )
    }
    
    private func setupWebSocketEvents() {
        print("Setting up WebSocket events...")
        websocket.onEventReceived = { [weak self] event in
            self?.handleWebSocketEvent(event: event)
        }
        websocket.addEventMessageHandler(self)
        websocket.$connectionState
            .sink { [weak self] newState in
                print("WebSocket connection state changed: \(newState)")
                self?.connectionState = newState
            }
            .store(in: &cancellables)
    }
    
    private func handleWebSocketEvent(event: String) {
        print("WebSocket event received: \(event)")
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
        DispatchQueue.main.async {
            switch entityId {
            case "binary_sensor.left_door_sensor":
                self.leftDoorClosed = (newState == "off")
            case "binary_sensor.right_door_sensor":
                self.rightDoorClosed = (newState == "off")
            case "binary_sensor.alarm_sensor":
                self.alarmOff = (newState == "off")
            default:
                print("Received state change for unknown sensor: \(entityId)")
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
            // Confirmation handling
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
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message from Watch: \(message)")
        if let entityId = message["entityId"] as? String,
           let newState = message["newState"] as? String {
            handleEntityAction(entityId: entityId, newState: newState)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive.")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated.")
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
// Extension of the ViewModel to manage WebSocket connection.
extension PhoneViewModel {
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
