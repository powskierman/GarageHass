//
//  SessionDelegator.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-16.
//

import Combine
import WatchConnectivity

// This class conforms to WCSessionDelegate and processes Watch Connectivity events.
class SessionDelegator: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    print("Activation state: \(activationState)")
    }
    
    let entityStateSubject: PassthroughSubject<EntityStateChange, Never>

    // Define a struct to encapsulate entity state changes.
    struct EntityStateChange {
        let entityId: String
        let newState: String
    }

    // The initializer accepts a PassthroughSubject for entity state changes.
    init(entityStateSubject: PassthroughSubject<EntityStateChange, Never>) {
        self.entityStateSubject = entityStateSubject
        super.init()
    }
    
    // Called when a message is received. It sends the received entity state change to the subject.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            // Extracts the 'entityId' and 'newState' from the message and sends it to the subject.
            if let entityId = message["entityId"] as? String, let newState = message["newState"] as? String {
                self.entityStateSubject.send(EntityStateChange(entityId: entityId, newState: newState))
            } else {
                print("There was an error processing the message")
            }
        }
    }
    
    func fetchStateAndUpdateWatch() {
        // Fetch the latest state from Home Assistant
        // ...

        // Then, send this state back to the watch
        let validSession = WCSession.default
        if validSession.isReachable {
            let updateMessage = ["entityId": "entity_id_here", "newState": "new_state_here"]
            validSession.sendMessage(updateMessage, replyHandler: nil, errorHandler: nil)
        }
    }
    
    // Below functions are required for protocol conformance on iOS but are not used in this demo.
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive.
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivation by activating a new session.
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        // Handle any changes to the watch state.
    }
    #endif
}

