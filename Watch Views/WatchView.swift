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
            // Pass watchViewModel to WatchEntityView for the left door
            WatchEntityView(viewModel: watchViewModel, entityType: .door(.left))
                .tabItem {
                    Image(systemName: watchViewModel.leftDoorClosed ? "door.open" : "door.closed")
                        .foregroundColor(watchViewModel.leftDoorClosed ? .blue : .red)
                    Text("Left Door")
                }
            
            WatchEntityView(viewModel: watchViewModel, entityType: .door(.right))
                .tabItem {
                    Image(systemName: watchViewModel.rightDoorClosed ? "door.closed" : "door.open")
                        .foregroundColor(watchViewModel.rightDoorClosed ? .blue : .red)
                    Text("Right Door")
                }
            
            WatchEntityView(viewModel: watchViewModel, entityType: .alarm)
                .tabItem {
                    Image(systemName: watchViewModel.alarmOff ? "alarm" : "alarm.fill")
                        .foregroundColor(watchViewModel.alarmOff ? .blue : .red)
                    Text("Alarm")
                }
        }
    }
}
