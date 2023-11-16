//
//  WatchGarageView.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-16.
//

import SwiftUI
import WatchConnectivity

struct WatchGarageView: View {
    @ObservedObject var watchViewModel = GarageDoorViewModel()

    var body: some View {
        TabView {
            // Pass watchViewModel to GarageDoorControlView for the left door
            GarageDoorControlView(viewModel: watchViewModel, door: .left)
                .tabItem {
                    Label("Left Door", systemImage: "garage")
                }

            // Pass watchViewModel to GarageDoorControlView for the right door
            GarageDoorControlView(viewModel: watchViewModel, door: .right)
                .tabItem {
                    Label("Right Door", systemImage: "garage")
                }

            // Pass watchViewModel to AlarmControlView
            AlarmControlView(viewModel: watchViewModel)
                .tabItem {
                    Label("Alarm", systemImage: "alarm")
                }
        }
    }
}
