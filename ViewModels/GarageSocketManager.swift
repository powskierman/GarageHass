import Foundation
import Combine
import WatchConnectivity
import HassFramework

class GarageSocketManager: ObservableObject {
    static let shared = GarageSocketManager()
    
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var connectionState: ConnectionState = .disconnected
    @Published var error: Error?
    @Published var hasErrorOccurred: Bool = false

    private let websocket: HassWebSocket
    private var cancellables = Set<AnyCancellable>()
    var onStateChange: ((String, String) -> Void)?

    init() {
        self.websocket = HassWebSocket.shared
        setupBindings()
        setupWebSocketEvents()
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
    
    private func setupBindings() {
        websocket.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
                if state == .connected {
                    self?.fetchInitialState()
                }
            }
            .store(in: &cancellables)
    }

    private func setupWebSocketEvents() {
        websocket.addEventMessageHandler(self)
    }

    func fetchInitialState() {
        websocket.fetchState { [weak self] statesArray in
            DispatchQueue.main.async {
                self?.processStates(statesArray)
            }
        }
    }

    private func processStates(_ states: [HAState]?) {
        guard let states = states else { return }
        for state in states {
            switch state.entityId {
            case "binary_sensor.left_door_sensor":
                leftDoorClosed = state.state == "off"
            case "binary_sensor.right_door_sensor":
                rightDoorClosed = state.state == "off"
            case "binary_sensor.alarm_sensor":
                alarmOff = state.state == "off"
            default:
                break
            }
        }
    }

    func handleEntityAction(entityId: String, newState: String? = nil) {
        guard websocket.isConnected() else {
            error = NSError(domain: "WebSocket", code: 1001, userInfo: [NSLocalizedDescriptionKey: "WebSocket is not connected."])
            hasErrorOccurred = true
            return
        }

        let service = newState ?? "toggle"
        let command = [
            "id": websocket.getNextMessageId(),
            "type": "call_service",
            "domain": determineDomain(entityId),
            "service": service,
            "service_data": ["entity_id": entityId]
        ] as [String : Any]

        if let jsonData = try? JSONSerialization.data(withJSONObject: command, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            websocket.sendTextMessage(jsonString)
        } else {
            error = NSError(domain: "WebSocket", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize command."])
            hasErrorOccurred = true
        }
    }

    private func determineDomain(_ entityId: String) -> String {
        if entityId.starts(with: "switch.") {
            return "switch"
        }
        return "homeassistant"
    }
}

extension GarageSocketManager: EventMessageHandler {
    func handleEventMessage(_ eventDetail: HAEventData.EventDetail) {
         let entityId = eventDetail.data.entityId
         guard let newState = eventDetail.data.newState?.state else { return }

        DispatchQueue.main.async {
            self.processStateChange(entityId: entityId, newState: newState)
        }
    }

    func handleResultMessage(_ text: String) {
        // Implement if needed for handling specific result messages.
    }

    private func processStateChange(entityId: String, newState: String) {
        let previousState: Bool
        switch entityId {
        case "binary_sensor.left_door_sensor":
            previousState = leftDoorClosed
            leftDoorClosed = newState == "off"
        case "binary_sensor.right_door_sensor":
            previousState = rightDoorClosed
            rightDoorClosed = newState == "off"
        case "binary_sensor.alarm_sensor":
            previousState = alarmOff
            alarmOff = newState == "off"
        default:
            return
        }

        if previousState != (newState == "off") {
            onStateChange?(entityId, newState)
            updateWatchState(entityId: entityId, newState: newState)
        }
    }

    private func updateWatchState(entityId: String, newState: String) {
        if WCSession.default.isReachable {
            let message = ["entityId": entityId, "newState": newState]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending state update to watch: \(error.localizedDescription)")
            }
        }
    }
}
