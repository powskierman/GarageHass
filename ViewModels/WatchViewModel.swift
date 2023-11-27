import Foundation
import WatchConnectivity

class WatchViewModel: NSObject, ObservableObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
 
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true

    override init() {
        super.init()
        print("Running setupWatchConnectivity")
        setupWatchConnectivity()
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("Watch Connectivity setup initiated.")
        } else {
            print("Watch Connectivity not supported on this device.")
        }
    }

    func sendCommandToPhone(entityId: String, newState: String) {
        print("Attempting to send command to iPhone: \(entityId), newState: \(newState)")
        if WCSession.default.isReachable {
            print("WCSession is reachable. Sending message.")
            let message = ["entityId": entityId, "newState": newState]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message to phone: \(error.localizedDescription)")
            }
        } else {
            print("WCSession is not reachable at the moment.")
        }
    }

    // ... Existing WCSessionDelegate methods ...

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message from phone:", message)
        DispatchQueue.main.async {
            if let entityId = message["entityId"] as? String,
               let newState = message["newState"] as? String {
                self.updateStateBasedOnMessage(entityId: entityId, newState: newState)
            }
        }
    }

    private func updateStateBasedOnMessage(entityId: String, newState: String) {
        print("Updating state based on message - Entity ID: \(entityId), New State: \(newState)")
        DispatchQueue.main.async {
            switch entityId {
            case "binary_sensor.left_door_sensor":
                print("LeftDoor Sensor State activated")
                // Toggling the state of the left garage door
                self.leftDoorClosed.toggle() // Toggle the current state
            case "binary_sensor.right_door_sensor":
                // Toggling the state of the right garage door
                self.rightDoorClosed.toggle() // Toggle the current state
            case "binary_sensor.alarm_sensor":
                // Toggling the alarm state
                self.alarmOff.toggle() // Toggle the current state
            default:
                print("Unknown entity ID: \(entityId)")
            }
        }
    }

//    private func updateStateBasedOnMessage(_ message: [String: Any]) {
//        if let leftDoorClosedValue = message["leftDoorClosed"] as? Bool {
//            self.leftDoorClosed = leftDoorClosedValue
//            print("Updated left door state to: \(leftDoorClosedValue)")
//        }
//        if let rightDoorClosedValue = message["rightDoorClosed"] as? Bool {
//            self.rightDoorClosed = rightDoorClosedValue
//            print("Updated right door state to: \(rightDoorClosedValue)")
//        }
//        if let alarmOffValue = message["alarmOff"] as? Bool {
//            self.alarmOff = alarmOffValue
//            print("Updated alarm state to: \(alarmOffValue)")
//        }
//    }


    func sessionReachabilityDidChange(_ session: WCSession) {
        print("SessionDelegator: WCSession reachability changed. Is now reachable: \(session.isReachable)")
    }
}
