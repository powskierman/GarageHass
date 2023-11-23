import Foundation
import WatchConnectivity

class WatchViewModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true

    override init() {
        super.init()
        setupWatchConnectivity()
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func sendCommandToPhone(entityId: String, newState: String) {
        print("Sending command to iPhone: \(entityId), newState: \(newState)")
        if WCSession.default.isReachable {
            let message = ["entityId": entityId, "newState": newState]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message to phone: \(error.localizedDescription)")
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message from phone")
        DispatchQueue.main.async {
            self.updateStateBasedOnMessage(message)
        }
    }

    private func updateStateBasedOnMessage(_ message: [String: Any]) {
        if let leftDoorClosedValue = message["leftDoorClosed"] as? Bool {
            self.leftDoorClosed = leftDoorClosedValue
        }
        if let rightDoorClosedValue = message["rightDoorClosed"] as? Bool {
            self.rightDoorClosed = rightDoorClosedValue
        }
        if let alarmOffValue = message["alarmOff"] as? Bool {
            self.alarmOff = alarmOffValue
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession Activation State: \(activationState)")
        if let error = error {
            print("Error in WCSession activation: \(error.localizedDescription)")
        } else {
            print("WCSession activated successfully. Is Reachable: \(session.isReachable)")
        }
    }
}
