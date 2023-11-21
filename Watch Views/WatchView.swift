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
            WatchEntityView(viewModel: watchViewModel, entityType: .door(.left)) // For left door
                .tabItem {
                    Label("Left Door", systemImage: "garage")
                }

            // Pass watchViewModel to GarageDoorControlView for the right door
            WatchEntityView(viewModel: watchViewModel, entityType: .door(.right)) // For right door

                .tabItem {
                    Label("Right Door", systemImage: "garage")
                }

            // Pass watchViewModel to AlarmControlView
            WatchEntityView(viewModel: watchViewModel, entityType: .alarm) // For alarm
                .tabItem {
                    Label("Alarm", systemImage: "alarm")
                }
        }
    }
}
