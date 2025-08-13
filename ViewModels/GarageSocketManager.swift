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

    public let websocket: HassWebSocket
    private var cancellables = Set<AnyCancellable>()
    var onStateChange: ((String, String) -> Void)?
    
    // Constants - matching GarageRestManager for consistency
    private struct Constants {
        static let entityIds = [
            "cover.leftdoor_left_garage_door",
            "cover.rightdoor_right_garage_door", 
            "binary_sensor.reversed_sensor"
        ]
        static let maxRetries = 3
        static let baseDelay = 2.0
    }
    
    // Connection retry logic
    private var retryAttempt = 0
    private var retryTimer: Timer?

    init() {
        self.websocket = HassWebSocket.shared
        setupBindings()
        setupWebSocketEvents()
    }

    func establishConnectionIfNeeded(completion: @escaping (Bool) -> Void) {
        if !websocket.isConnected() {
            connectWithRetry(completion: completion)
        } else {
            print("[GarageSocketManager] WebSocket already connected.")
            completion(true)
        }
    }
    
    private func connectWithRetry(attempt: Int = 1, completion: @escaping (Bool) -> Void) {
        websocket.connect { [weak self] success in
            if success {
                print("[GarageSocketManager] WebSocket connected successfully")
                self?.retryAttempt = 0
                self?.retryTimer?.invalidate()
                self?.retryTimer = nil
                completion(true)
            } else if attempt < Constants.maxRetries {
                let delay = Constants.baseDelay * Double(attempt)
                print("[GarageSocketManager] Connection failed, retry \(attempt)/\(Constants.maxRetries) in \(delay)s")
                
                self?.retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                    self?.connectWithRetry(attempt: attempt + 1, completion: completion)
                }
            } else {
                print("[GarageSocketManager] Connection failed after \(Constants.maxRetries) attempts")
                self?.handleConnectionError(NSError(domain: "GarageSocketManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to connect after multiple attempts"]))
                completion(false)
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
        guard let states = states else { 
            handleConnectionError(NSError(domain: "GarageSocketManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "No states received"]))
            return 
        }
        
        for state in states {
            updateEntityState(entityId: state.entityId, newState: state.state)
        }
    }
    
    private func updateEntityState(entityId: String, newState: String) {
        switch entityId {
        case "cover.leftdoor_left_garage_door":
            leftDoorClosed = newState == "closed"
        case "cover.rightdoor_right_garage_door":
            rightDoorClosed = newState == "closed"
        case "binary_sensor.reversed_sensor":
            alarmOff = newState == "off"
        default:
            print("[GarageSocketManager] Unknown entity: \(entityId)")
        }
    }

    func handleEntityAction(entityId: String, newState: String? = nil) {
        guard websocket.isConnected() else {
            handleConnectionError(NSError(domain: "GarageSocketManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "WebSocket is not connected."]))
            return
        }
        
        print("[GarageSocketManager] Handling entity action: \(entityId), newState: \(String(describing: newState))")
        let service = newState ?? "toggle"
        let command = [
            "id": websocket.getNextMessageId(),
            "type": "call_service",
            "domain": determineDomain(entityId),
            "service": service,
            "service_data": ["entity_id": entityId]
        ] as [String : Any]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: command, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                websocket.sendTextMessage(jsonString)
            } else {
                throw NSError(domain: "GarageSocketManager", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON to string"])
            }
        } catch {
            handleConnectionError(error)
        }
    }

    private func determineDomain(_ entityId: String) -> String {
        let components = entityId.components(separatedBy: ".")
        guard let domain = components.first else {
            return "homeassistant"
        }
        
        switch domain {
        case "switch":
            return "switch"
        case "script":
            return "script"
        case "light":
            return "light"
        case "cover":
            return "cover"
        default:
            return "homeassistant"
        }
    }
    
    private func handleConnectionError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.hasErrorOccurred = true
        }
    }
    
    deinit {
        retryTimer?.invalidate()
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
        print("[GarageSocketManager] Processing state change: \(entityId), newState: \(newState)")
        
        let previousState = getCurrentState(for: entityId)
        updateEntityState(entityId: entityId, newState: newState)
        let newBoolState = (newState == "off")
        
        if previousState != newBoolState {
            onStateChange?(entityId, newState)
            updateWatchState(entityId: entityId, newState: newState)
        }
    }
    
    private func getCurrentState(for entityId: String) -> Bool {
        switch entityId {
        case "cover.leftdoor_left_garage_door":
            return leftDoorClosed
        case "cover.rightdoor_right_garage_door":
            return rightDoorClosed
        case "binary_sensor.reversed_sensor":
            return alarmOff
        default:
            return false
        }
    }

    private func updateWatchState(entityId: String, newState: String) {
        guard WCSession.default.activationState == .activated else {
            print("[GarageSocketManager] Watch session not activated")
            return
        }
        
        if WCSession.default.isReachable {
            let message = ["entity_id": entityId, "newState": newState]
            WCSession.default.sendMessage(message, replyHandler: { response in
                print("[GarageSocketManager] Watch acknowledged state update: \(response)")
            }) { [weak self] error in
                print("[GarageSocketManager] Error sending state update to watch: \(error.localizedDescription)")
                // Optionally handle watch communication errors
                self?.handleWatchError(error)
            }
        } else {
            print("[GarageSocketManager] Watch not reachable, state update skipped")
        }
    }
    
    private func handleWatchError(_ error: Error) {
        // Could implement retry logic or user notification here
        print("[GarageSocketManager] Watch communication failed: \(error)")
    }
}


