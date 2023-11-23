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

        // Activate WCSession if supported
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession Activation State: \(activationState)")
        if let error = error {
            print("WCSession activation error: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received state update from phone:", message)

        DispatchQueue.main.async {
            if let leftDoorClosed = message["leftDoorClosed"] as? Bool {
                let newState = leftDoorClosed ? "off" : "on"
                self.entityStateSubject.send(EntityStateChange(entityId: "left_door", newState: newState))
            }
            if let rightDoorClosed = message["rightDoorClosed"] as? Bool {
                let newState = rightDoorClosed ? "off" : "on"
                self.entityStateSubject.send(EntityStateChange(entityId: "right_door", newState: newState))
            }
            if let alarmOff = message["alarmOff"] as? Bool {
                let newState = alarmOff ? "off" : "on"
                self.entityStateSubject.send(EntityStateChange(entityId: "alarm", newState: newState))
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
