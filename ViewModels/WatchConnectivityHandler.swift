import Foundation
import WatchConnectivity
import HassFramework

protocol AppStateUpdateDelegate {
    func appDidBecomeActive()
    func appDidEnterBackground()
}

class WatchConnectivityHandler: NSObject, ObservableObject, WCSessionDelegate {
    private var session: WCSession?
    let webSocketManager = GarageSocketManager.shared
    var stateDelegate: AppStateUpdateDelegate?
    // Property to track if the app is active
    var isAppActive: Bool = false
    
    override init() {
        super.init()
        print("[WatchConnectivityHandler] Initializing and setting up WatchConnectivity")
        setupWatchConnectivity()
        setupWebSocketManagerListener()
    }
    
    private func setupWebSocketManagerListener() {
        GarageSocketManager.shared.onStateChange = { [weak self] entityId, newState in
            self?.updateStateAndNotifyWatch(entityId: entityId, newState: newState)
            print("WebSocket manager listener set up")
        }
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("WCSession setup initiated")
        } else {
            print("WCSession not supported on this device")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activation did complete. State: \(activationState), Error: \(String(describing: error))")
    }
    
    func appDidBecomeActive() {
        print("[WatchConnectivityHandler] App became active")
        manageWebSocketConnection()
        setupWatchConnectivity()
    }

    func appDidEnterBackground() {
        print("[WatchConnectivityHandler] App entered background")
        // Consider any additional handling needed when the app goes into the background
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[WatchConnectivityHandler] WCSession reachability changed: \(session.isReachable)")
        if session.isReachable {
            // Consider re-establishing or checking the connection if necessary
        }
    }

    
//    func appDidBecomeActive() {
//        print("App became active")
//        // Establish websocket
//        manageWebSocketConnection()
//        // Establish WatchConnectivity
//        print("Setting up WatchConnectivity")
//        setupWatchConnectivity()
//    }
//    
//    func appDidEnterBackground() {
//        print("App did enter background - handling as needed")
//    }
//    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive.")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated. Reactivating...")
        session.activate()
    }
//    
//    func sessionReachabilityDidChange(_ session: WCSession) {
//        print("WCSession reachability changed. Is now reachable: \(session.isReachable)")
//    }
    
    // Method to handle the initial state request from the watch
    func handleInitialStateRequest(replyHandler: @escaping ([String: Any]) -> Void) {
        // Fetch the initial state using GarageSocketManager
        GarageSocketManager.shared.fetchInitialState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            
            // Prepare the response with the updated states
            let response: [String: Any] = ["leftDoorClosed": GarageSocketManager.shared.leftDoorClosed,
                                           "rightDoorClosed": GarageSocketManager.shared.rightDoorClosed,
                                           "alarmOff": GarageSocketManager.shared.alarmOff]
            
            // Send the response back to the watch
            replyHandler(response)
        }
    }
    
    // Utility method to process the states (similar to what you have in GarageSocketManager)
    private func processStates(_ states: [HAState]?) {
        guard let states = states else { return }
        for state in states {
            switch state.entityId {
            case "binary_sensor.left_door_sensor":
                GarageSocketManager.shared.leftDoorClosed = state.state == "off"
            case "binary_sensor.right_door_sensor":
                GarageSocketManager.shared.rightDoorClosed = state.state == "off"
            case "binary_sensor.alarm_sensor":
                GarageSocketManager.shared.alarmOff = state.state == "off"
            default:
                break
            }
        }
    }
    
    
    func updateStateAndNotifyWatch(entityId: String, newState: String) {
        let session = WCSession.default
        print("[WatchConnectivityHandler] Preparing to send state update to watch. WCSession isReachable: \(session.isReachable), isActivated: \(session.activationState == .activated)")
        
        guard session.isReachable else {
            print("[WatchConnectivityHandler] WCSession is not reachable. State update not sent.")
            return
        }
        
        print("[WatchConnectivityHandler] Sending state update to watch: entityId = \(entityId), newState = \(newState)")
        let message = ["entityId": entityId, "newState": newState]
        session.sendMessage(message, replyHandler: nil) { error in
            print("[WatchConnectivityHandler] Error sending state update to watch: \(error.localizedDescription)")
        }
    }
    
    // Handle incoming messages from the watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("[WatchConnectivityHandler] Received message from watch: \(message)")
        
        if let request = message["request"] as? String {
            switch request {
            case "webSocketStatus":
                let isWebSocketConnected = HassWebSocket.shared.isConnected()
                replyHandler(["webSocketStatus": isWebSocketConnected])
            case "initialState":
                handleInitialStateRequest(replyHandler: replyHandler) // Pass the replyHandler
            default:
                print("[WatchConnectivityHandler] Unrecognized request type: \(request)")
                replyHandler(["error": "Unrecognized request type"])
            }
        } else if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
            processCommand(["entityId": entityId, "newState": newState], replyHandler: replyHandler) // Pass the replyHandler
        } else {
            // Handle unrecognized message format
            replyHandler(["error": "Unrecognized message format"])
        }
    }
    
    private func processCommand(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
            GarageSocketManager.shared.handleEntityAction(entityId: entityId, newState: newState)
        }
        replyHandler(["confirmation": "Command processed"])
    }
    
    func handleReceivedMessage(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("Handling received message: \(message)")

        // Check the current state of the app
        // Assuming you have a way to check if the app is active or in background
        if isAppActive {
            // Process the message normally if the app is active
            processMessage(message, replyHandler: replyHandler)
        } else {
            // Handle differently if the app is in the background
            print("[WatchConnectivityHandler] App is in background. Deferred processing.")
            // Here you can queue the message or respond with a specific error/message
            replyHandler(["error": "App is in background. Unable to process message currently."])
        }
    }

    private func processMessage(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let requestType = message["request"] as? String {
            handleRequestTypeMessage(requestType, message: message, replyHandler: replyHandler)
        } else if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
            handleEntityActionMessage(entityId: entityId, newState: newState)
        } else {
            print("[WatchConnectivityHandler] Unrecognized message format")
            replyHandler(["error": "Unrecognized message format"])
        }
    }

    
//    private func processMessage(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
//        if let requestType = message["request"] as? String {
//            handleRequestTypeMessage(requestType, message: message, replyHandler: replyHandler)
//        } else if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
//            handleEntityActionMessage(entityId: entityId, newState: newState)
//        } else {
//            print("[WatchConnectivityHandler] Unrecognized message format")
//            replyHandler(["error": "Unrecognized message format"])
//        }
//    }


    private func handleEntityActionMessage(_ entityId: String, newState: String) {
        // Your existing logic for handling entity action messages
    }

    
//    func handleReceivedMessage(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
//        print("Handling received message: \(message)")
//
//        if let requestType = message["request"] as? String {
//            handleRequestTypeMessage(requestType, message: message, replyHandler: replyHandler)
//        } else if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
//            handleEntityActionMessage(entityId: entityId, newState: newState)
//        } else {
//            print("[WatchConnectivityHandler] Unrecognized message format")
//            replyHandler(["error": "Unrecognized message format"])
//        }
//    }
    
    private func handleRequestTypeMessage(_ requestType: String, message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("Processing request - Type: \(requestType)")
        switch requestType {
        case "webSocketStatus":
            let isWebSocketConnected = HassWebSocket.shared.isConnected()
            replyHandler(["webSocketStatus": isWebSocketConnected])
        
        case "initialState":
            GarageSocketManager.shared.fetchInitialState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let response: [String: Any] = ["leftDoorClosed": GarageSocketManager.shared.leftDoorClosed,
                                               "rightDoorClosed": GarageSocketManager.shared.rightDoorClosed,
                                               "alarmOff": GarageSocketManager.shared.alarmOff]
                replyHandler(response)
            }
        
        default:
            print("[WatchConnectivityHandler] Unrecognized request type: \(requestType)")
            replyHandler(["error": "Unrecognized request type"])
        }
    }

    private func handleEntityActionMessage(entityId: String, newState: String) {
        print("Processing command - Entity ID: \(entityId), New State: \(newState)")
        GarageSocketManager.shared.handleEntityAction(entityId: entityId, newState: newState)
    }
    

    private func manageWebSocketConnection() {
        if !HassWebSocket.shared.isConnected() {
            GarageSocketManager.shared.establishConnectionIfNeeded { success in
                if success {
                    print("[WatchConnectivityHandler] WebSocket connection established successfully.")
                } else {
                    print("[WatchConnectivityHandler] Failed to establish WebSocket connection.")
                }
            }
        } else {
            print("[WatchConnectivityHandler] WebSocket is already connected.")
        }
    }
}
