//
//  WatchGarageHassApp.swift
//  WatchGarageHass
//
//  Created by Michel Lapointe on 2023-11-16.
//

import SwiftUI

@main
struct WatchGarageHassApp: App {
    @StateObject var garageDoorViewModel = GarageDoorViewModel()
    var body: some Scene {
        WindowGroup {
            WatchGarageView()
        }
    }
}
