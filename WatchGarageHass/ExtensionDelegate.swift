//
//  ExtensionDelegate.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-17.
//

import WatchKit
import Combine
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    var sessionDelegator: SessionDelegator!

    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            let entityStateSubject = PassthroughSubject<SessionDelegator.EntityStateChange, Never>()
            sessionDelegator = SessionDelegator(entityStateSubject: entityStateSubject)
            WCSession.default.delegate = sessionDelegator
            WCSession.default.activate()
        }
    }

    // Other WKExtensionDelegate methods...
}
