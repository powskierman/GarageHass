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
        setupWatchConnectivity()
        setupWebSocketManagerListener()
        print("WatchConnectivityHandler initialized")
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

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("Received message from watch: \(message)")
        handleReceivedMessage(message)
    }

    func handleReceivedMessage(_ message: [String: Any]) {
        print("Handling received message: \(message)")
        if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
            print("Processing command - Entity ID: \(entityId), New State: \(newState)")
            webSocketManager.handleEntityAction(entityId: entityId, newState: newState)
        }
    }

    func updateStateAndNotifyWatch(entityId: String, newState: String) {
        if WCSession.default.isReachable {
            print("Sending state to watch")
            let message = ["entityId": entityId, "newState": newState]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending state update to watch: \(error.localizedDescription)")
            }
        }
    }

    func appDidBecomeActive() {
        print("App did become active - handling as needed")
        // Handle app becoming active
    }

    func appDidEnterBackground() {
        print("App did enter background - handling as needed")
        // Handle app entering background
    }
}
