import Foundation
import WatchConnectivity

class WatchConnectivityHandler: NSObject, WCSessionDelegate {
    private var session: WCSession?
    let webSocketManager = GarageSocketManager.shared

    override init() {
        super.init()
        setupWatchConnectivity()
        setupWebSocketManagerListener()
    }
    
    private func setupWebSocketManagerListener() {
        GarageSocketManager.shared.onStateChange = { [weak self] entityId, newState in
            self?.updateStateAndNotifyWatch(entityId: entityId, newState: newState)
        }
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("WatchConnectivityHandler: WCSession setup initiated.")
        } else {
            print("WatchConnectivityHandler: WCSession not supported on this device.")
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WatchConnectivityHandler: WCSession activation did complete. State: \(activationState), Error: \(String(describing: error))")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WatchConnectivityHandler: WCSession became inactive.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WatchConnectivityHandler: WCSession deactivated. Reactivating...")
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("WatchConnectivityHandler: WCSession reachability changed. Is now reachable: \(session.isReachable)")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
         print("WatchConnectivityHandler: Received message from watch: \(message)")

         // Extract entityId and newState from the message
         if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
             print("WatchConnectivityHandler: Processing command - Entity ID: \(entityId), New State: \(newState)")
             
             // Forward the command to the WebSocketManager
             webSocketManager.handleEntityAction(entityId: entityId, newState: newState)
         }
     }
        
    func updateStateAndNotifyWatch(entityId: String, newState: String) {
        // Update the state in WebSocketManager if needed
        // Example: WebSocketManager.shared.leftDoorClosed = newState == "closed"
        
        // Check if the watch session is reachable and send the updated state
        if WCSession.default.isReachable {
            print("Send state to watch")
            let message = ["entityId": entityId, "newState": newState]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending state update to watch: \(error.localizedDescription)")
            }
        }
    }

    // Implement any additional methods needed for WCSessionDelegate
}
