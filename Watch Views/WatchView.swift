//
//  WatchView.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-16.
//

import SwiftUI
import WatchConnectivity

struct WatchView: View {
    @ObservedObject var watchViewModel = WatchViewModel()

    var body: some View {
        TabView {
            // Pass watchViewModel to GarageDoorControlView for the left door
            WatchDoorView(viewModel: watchViewModel, door: .left)
                .tabItem {
                    Label("Left Door", systemImage: "garage")
                }

            // Pass watchViewModel to GarageDoorControlView for the right door
            WatchDoorView(viewModel: watchViewModel, door: .right)
                .tabItem {
                    Label("Right Door", systemImage: "garage")
                }

            // Pass watchViewModel to AlarmControlView
            WatchAlarmView(viewModel: watchViewModel)
                .tabItem {
                    Label("Alarm", systemImage: "alarm")
                }
        }
    }
}
