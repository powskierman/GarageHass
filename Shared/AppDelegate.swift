//
//  AppDelegate.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-17.
//

import SwiftUI
import Combine
import WatchConnectivity

class AppDelegate: NSObject, UIApplicationDelegate {
    var sessionDelegator: SessionDelegator!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if WCSession.isSupported() {
            let entityStateSubject = PassthroughSubject<SessionDelegator.EntityStateChange, Never>()
            sessionDelegator = SessionDelegator(entityStateSubject: entityStateSubject)
            WCSession.default.delegate = sessionDelegator
            WCSession.default.activate()
        }
        return true
    }
}
