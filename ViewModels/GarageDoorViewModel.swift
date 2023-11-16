//
//  GarageDoorViewModel.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-16.
//

import Foundation
import WatchConnectivity

class GarageDoorViewModel: ObservableObject {
    func sendCommandToPhone(entityId: String, newState: String) {
        if WCSession.default.isReachable {
            let message = ["entityId": entityId, "newState": newState]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
}
