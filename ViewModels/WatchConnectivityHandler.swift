import Foundation
import WatchConnectivity

protocol AppStateUpdateDelegate {
    func appDidBecomeActive()
    func appDidEnterBackground()
}

class WatchConnectivityHandler: NSObject, ObservableObject, WCSessionDelegate {
    private var session: WCSession?
    let webSocketManager = GarageSocketManager.shared
    var stateDelegate: AppStateUpdateDelegate?

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
        print("App did become active - handling as needed")
    }

    func appDidEnterBackground() {
        print("App did enter background - handling as needed")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated. Reactivating...")
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("WCSession reachability changed. Is now reachable: \(session.isReachable)")
    }

    func handleReceivedMessage(_ message: [String: Any]) {
        print("Handling received message: \(message)")
        if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
            print("Processing command - Entity ID: \(entityId), New State: \(newState)")
            webSocketManager.handleEntityAction(entityId: entityId, newState: newState)
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
            // Check if the message is a request for initial state
            if message["request"] as? String == "initialState" {
                // Fetch the current states
                let leftDoorClosed = webSocketManager.leftDoorClosed
                let rightDoorClosed = webSocketManager.rightDoorClosed
                let alarmOff = webSocketManager.alarmOff

                // Prepare and send the response
                let response = ["leftDoorClosed": leftDoorClosed,
                                "rightDoorClosed": rightDoorClosed,
                                "alarmOff": alarmOff]
                replyHandler(response)
            } else {
                // Handle other messages if needed
                handleReceivedMessage(message)
            }
        }
    
//    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
//        print("Received message from watch: \(message)")
//        if let requestType = message["request"] as? String, requestType == "initialState" {
//            // Fetch the initial state
//            let initialState: [String: Any] = [
//                "leftDoorClosed": webSocketManager.leftDoorClosed,
//                "rightDoorClosed": webSocketManager.rightDoorClosed,
//                "alarmOff": webSocketManager.alarmOff
//            ]
//            
//            // Send the initial state back to the watch
//            replyHandler(initialState)
//        }
//        replyHandler(initialState)
//    } else {
//        // Handle other messages if needed
//        handleReceivedMessage(message)
//    }
    }


