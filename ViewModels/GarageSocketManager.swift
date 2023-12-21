import Foundation
import Combine
import HassFramework
import Starscream
import WatchConnectivity

class GarageSocketManager: ObservableObject {
    static let shared = GarageSocketManager(websocket: HassWebSocket.shared)
    
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var connectionState: HassFramework.ConnectionState = .disconnected
    @Published var error: Error?
    @Published var hasErrorOccurred: Bool = false
    
    var websocket: HassWebSocket
    private var cancellables = Set<AnyCancellable>()
    var onStateChange: ((String, String) -> Void)?
    var completionHandlers: [Int: ([HAState]) -> Void] = [:]
    private var messageId = 0
    
    init(websocket: HassWebSocket) {
        self.websocket = websocket
        websocket.addEventMessageHandler(self)
        
        // Observe changes in the websocket's connection state
        websocket.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
    }
    
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        switch event {
        case .connected(_):
            self.websocket.connectionState = .connected
        case .disconnected(_, _):
            self.websocket.connectionState = .disconnected
        case .text(let text):
            handleWebSocketTextResponse(text)
        default:
            break
        }
    }
    
    func connectSendCommand(command: String, completion: @escaping (Bool) -> Void) {
        establishConnectionIfNeeded { isConnected in
            guard isConnected else {
                completion(false)
                return
            }
            
            if self.websocket.isAuthenticated {
                self.websocket.sendTextMessage(command)
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    public func processStateChange(entityId: String, newState: String) {
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
                return
            }
            
            if WCSession.default.isReachable {
                let message = ["entityId": entityId, "newState": newState]
                WCSession.default.sendMessage(message, replyHandler: nil) { error in
                    print("Error sending state update to watch: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func establishConnectionIfNeeded(completion: @escaping (Bool) -> Void) {
        guard !websocket.isConnected() else {
            completion(true)
            return
        }
        
        websocket.connect { success in
            DispatchQueue.main.async {
                if success {
                    self.websocket.subscribeToEvents()
                    self.error = nil
                    completion(true)
                } else {
                    self.error = NSError(domain: "WebSocket", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to establish WebSocket connection."])
                    completion(false)
                }
            }
        }
    }
    
    func forceReconnect() {
        if HassWebSocket.shared.isConnected() {
            HassWebSocket.shared.disconnect()
        }
        establishConnectionIfNeeded()
    }
    
    func handleEntityAction(entityId: String, newState: String? = nil) {
        establishConnectionIfNeeded { success in
            guard success else {
                return
            }
            
            let service = newState ?? "toggle"
            let messageId = self.websocket.getNextMessageId()
            
            let serviceData: [String: Any] = ["entity_id": entityId]
            let callServiceMessage: [String: Any] = [
                "id": messageId,
                "type": "call_service",
                "domain": "switch",
                "service": service,
                "service_data": serviceData
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: callServiceMessage, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                self.connectSendCommand(command: jsonString) { success in
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
    }

    private func handleWebSocketTextResponse(_ text: String) {
        guard let data = text.data(using: .utf8),
              let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []),
              let responseDict = jsonResponse as? [String: Any] else {
            return
        }
        
        if let id = responseDict["id"] as? Int, completionHandlers.keys.contains(id) {
            handleStateResponse(responseDict, messageId: id)
        }
    }
    
    private func handleStateResponse(_ response: [String: Any], messageId: Int) {
        if let results = response["result"] as? [[String: Any]] {
            let states: [HAState] = results.compactMap { stateDict in
                guard let jsonData = try? JSONSerialization.data(withJSONObject: stateDict, options: []),
                      let state = try? JSONDecoder().decode(HAState.self, from: jsonData) else {
                    return nil
                }
                return state
            }
            
            if let completion = completionHandlers[messageId] {
                completion(states)
                completionHandlers.removeValue(forKey: messageId)
            }
        }
    }
}
