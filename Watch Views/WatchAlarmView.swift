//
//  WatchAlarmView.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-16.
//

//import SwiftUI
//
//struct WatchAlarmView: View {
//    @State private var alarmOff: Bool = true // This state can be modified based on actual alarm state if needed
//    var viewModel: WatchViewModel
//    
//    var body: some View {
//        Button(action: {
//            toggleAlarm()
//        }) {
//            VStack {
//                Image(systemName: alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
//                    .resizable()
//                    .scaledToFit()
//                Text("Alarm")
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(alarmOff ? Color.teal : Color.pink)
//    }
//
//    private func toggleAlarm() {
//        let entityId = "switch.alarm_sensor"
//        viewModel.sendCommandToPhone(entityId: entityId, newState: "toggle")
//        print("Sent alarm command to phone: \(entityId)")
//        // alarmOff.toggle() // Update local state
//    }
//        .confirmationDialog("Toggle Alarm", isPresented: $showingAlarmConfirmation) {
//                Button("Confirm", role: .destructive) {
//                    // Calls the method to handle confirmed alarm action in the view model.
//                    viewModel.handleAlarmActionConfirmed()
//                }
//            }
//    }

import SwiftUI

struct WatchAlarmView: View {
    @State private var alarmOff: Bool = true // This state can be modified based on actual alarm state
    @State private var showingAlarmConfirmation = false
    @ObservedObject var viewModel: WatchViewModel // Replace 'ViewModel' with your actual view model type

    var body: some View {
        VStack {
            Button(action: {
                // When button is pressed, it shows a confirmation dialog.
                self.showingAlarmConfirmation = true
            }) {
                                  Image(systemName: alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
                                    .resizable()
                                    .scaledToFit()
                                Text("Alarm")
                    .foregroundColor(alarmOff ? .teal : .pink)
            }
            .confirmationDialog("Toggle Alarm", isPresented: $showingAlarmConfirmation) {
                Button("Confirm", role: .destructive) {
                    toggleAlarm()
                }
            }
        }
        .onAppear() {
    //        viewModel.establishConnectionIfNeeded()
        }
    }

    private func toggleAlarm() {
        let entityId = "switch.alarm_sensor"
        viewModel.sendCommandToPhone(entityId: entityId, newState: "toggle")
        print("Sent alarm command to phone: \(entityId)")
        // viewModel.alarmOff.toggle() // Update local state if needed
    }
}
