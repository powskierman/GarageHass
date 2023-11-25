import Combine
import WatchConnectivity

class SessionDelegator: NSObject, WCSessionDelegate {
    let entityStateSubject: PassthroughSubject<EntityStateChange, Never>

    struct EntityStateChange {
        let entityId: String
        let newState: String
    }

    init(entityStateSubject: PassthroughSubject<EntityStateChange, Never>) {
        self.entityStateSubject = entityStateSubject
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("SessionDelegator: WCSession default session set and activated")
        } else {
            print("SessionDelegator: WCSession not supported on this device")
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("SessionDelegator: WCSession activation did complete with state: \(activationState), error: \(String(describing: error))")
        if let error = error {
            print("WCSession activation error: \(error.localizedDescription)")
        }
    }

//    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
//        print("SessionDelegator: Received message from watch:", message)
//
//        DispatchQueue.main.async {
//            // Handling the general case where the message contains entityId and newState
////            if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
////                print("Processing command - Entity ID: \(entityId), New State: \(newState)")
////                self.entityStateSubject.send(EntityStateChange(entityId: entityId, newState: newState))
////            }
//
//            // Assign the values to variables, which will be nil if the casting fails
//             let entityId = message["entityId"] as? String
//             let newState = message["newState"] as? String
//
//             // Print out entityId and newState to debug their values
//             print("entityId:", entityId ?? "nil", "newState:", newState ?? "nil")
//
//             // Check if both entityId and newState have valid values
//             if let entityId = entityId, let newState = newState {
//                 print("Processing command - Entity ID: \(entityId), New State: \(newState)")
//                 self.entityStateSubject.send(EntityStateChange(entityId: entityId, newState: newState))
//             }
//
//            
//            // Handling specific cases for leftDoorClosed, rightDoorClosed, and alarmOff
//            if let leftDoorClosed = message["switch.left_garage_door"] as? Bool {
//                let newState = leftDoorClosed ? "off" : "on"
//                self.entityStateSubject.send(EntityStateChange(entityId: "switch.left_garage_door", newState: newState))
//            }
//            if let rightDoorClosed = message["rightDoorClosed"] as? Bool {
//                let newState = rightDoorClosed ? "off" : "on"
//                self.entityStateSubject.send(EntityStateChange(entityId: "right_door", newState: newState))
//            }
//            if let alarmOff = message["alarmOff"] as? Bool {
//                let newState = alarmOff ? "off" : "on"
//                self.entityStateSubject.send(EntityStateChange(entityId: "alarm", newState: newState))
//            }
//        }
//    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("SessionDelegator: Received message from watch:", message)

        DispatchQueue.main.async {
            if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
                self.entityStateSubject.send(EntityStateChange(entityId: entityId, newState: newState))
            }
        }
    }

    

    // Additional methods for WCSessionDelegate as required by iOS
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive.")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated.")
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("WCSession Watch state changed.")
    }
    #endif
}
