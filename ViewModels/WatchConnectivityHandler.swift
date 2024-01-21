import Foundation
import WatchConnectivity
import HassFramework

protocol AppStateUpdateDelegate {
    func appDidBecomeActive()
    func appDidEnterBackground()
}

class WatchConnectivityHandler: NSObject, ObservableObject, WCSessionDelegate {
    private var session: WCSession?
    var stateDelegate: AppStateUpdateDelegate?
    var isAppActive: Bool = false
    
    override init() {
        super.init()
        print("[WatchConnectivityHandler] Initializing and setting up WatchConnectivity")
        setupWatchConnectivity()
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
        setupWatchConnectivity()
    }

    func appDidEnterBackground() {
        print("[WatchConnectivityHandler] App entered background")
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[WatchConnectivityHandler] WCSession reachability changed: \(session.isReachable)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive.")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated. Reactivating...")
        session.activate()
    }

    func handleInitialStateRequest(replyHandler: @escaping ([String: Any]) -> Void) {
        // Use GarageRestManager to fetch the initial state
        GarageRestManager.shared.fetchInitialState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let response: [String: Any] = [
                "leftDoorClosed": GarageRestManager.shared.leftDoorClosed,
                "rightDoorClosed": GarageRestManager.shared.rightDoorClosed,
                "alarmOff": GarageRestManager.shared.alarmOff
            ]
            replyHandler(response)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("[WatchConnectivityHandler] Received message from watch: \(message)")
        
        if let request = message["request"] as? String, request == "initialState" {
            handleInitialStateRequest(replyHandler: replyHandler)
        } else {
            // Handle other messages or commands here
            replyHandler(["error": "Unrecognized message format or command"])
        }
    }
}
