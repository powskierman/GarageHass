import Foundation
import WatchConnectivity

class GarageDoorViewModel: NSObject, ObservableObject, WCSessionDelegate {
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func sendCommandToPhone(entityId: String, newState: String) {
        if WCSession.default.isReachable {
            let message = ["entityId": entityId, "newState": newState]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }


    // WCSessionDelegate method
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession Activation State: \(activationState)")
        if let error = error {
            print("Error in WCSession activation: \(error.localizedDescription)")
        } else {
            print("WCSession activated successfully. Is Reachable: \(session.isReachable)")
        }
    }
}
