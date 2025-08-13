//
//  AppDelegate.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2024-06-10.
//

import Foundation
import UIKit
import UserNotifications
import WatchConnectivity

extension Notification.Name {
    static let didReceiveNotification = Notification.Name("didReceiveNotification")
    static let didUpdateSensorState = Notification.Name("didUpdateSensorState")
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        registerForPushNotifications()
        setupWatchConnectivity()
        return true
    }
    
    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("[AppDelegate] WatchConnectivity activated")
        }
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self.getNotificationSettings()
        }
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Process the device token to send it to the server
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle push notification received
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Handle the notification
        NotificationCenter.default.post(name: .didReceiveNotification, object: nil, userInfo: userInfo)
        completionHandler()
    }
}

// MARK: - WCSessionDelegate
extension AppDelegate: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("[AppDelegate] WCSession activation failed: \(error)")
        } else {
            print("[AppDelegate] WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[AppDelegate] WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("[AppDelegate] WCSession deactivated")
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("[AppDelegate] Received message from watch: \(message)")
        
        guard let action = message["action"] as? String else {
            replyHandler(["success": false, "error": "No action specified"])
            return
        }
        
        switch action {
        case "requestState":
            handleStateRequest(replyHandler: replyHandler)
        case "toggleSwitch":
            guard let entityId = message["entityId"] as? String else {
                replyHandler(["success": false, "error": "No entityId specified"])
                return
            }
            handleToggleSwitch(entityId: entityId, replyHandler: replyHandler)
        case "executeScript":
            guard let entityId = message["entityId"] as? String else {
                replyHandler(["success": false, "error": "No entityId specified"])
                return
            }
            handleExecuteScript(entityId: entityId, replyHandler: replyHandler)
        default:
            replyHandler(["success": false, "error": "Unknown action: \(action)"])
        }
    }
    
    private func handleStateRequest(replyHandler: @escaping ([String : Any]) -> Void) {
        let manager = GarageRestManager.shared
        let state = [
            "leftDoorClosed": manager.leftDoorClosed,
            "rightDoorClosed": manager.rightDoorClosed,
            "alarmOff": manager.alarmOff
        ]
        replyHandler(state)
    }
    
    private func handleToggleSwitch(entityId: String, replyHandler: @escaping ([String : Any]) -> Void) {
        let manager = GarageRestManager.shared
        manager.toggleSwitch(entityId: entityId)
        
        // Reply immediately with success, then send state update after delay
        replyHandler(["success": true])
        
        // Send state update to watch after successful toggle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.sendStateUpdateToWatch()
        }
    }
    
    private func handleExecuteScript(entityId: String, replyHandler: @escaping ([String : Any]) -> Void) {
        let manager = GarageRestManager.shared
        manager.handleScriptAction(entityId: entityId)
        
        // Reply immediately with success
        replyHandler(["success": true])
    }
    
    private func sendStateUpdateToWatch() {
        guard WCSession.default.isReachable else { return }
        
        let manager = GarageRestManager.shared
        let message = [
            "action": "stateUpdate",
            "leftDoorClosed": manager.leftDoorClosed,
            "rightDoorClosed": manager.rightDoorClosed,
            "alarmOff": manager.alarmOff
        ] as [String : Any]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("[AppDelegate] Failed to send state update to watch: \(error)")
        }
    }
}

