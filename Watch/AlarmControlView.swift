//
//  AlarmControlView.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-16.
//

import SwiftUI

struct AlarmControlView: View {
    @State private var alarmOff: Bool = true // This state can be modified based on actual alarm state if needed
    var viewModel: WatchViewModel
    
    var body: some View {
        Button(action: {
            toggleAlarm()
        }) {
            VStack {
                Image(systemName: alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
                    .resizable()
                    .scaledToFit()
                Text("Alarm")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(alarmOff ? Color.teal : Color.pink)
    }

    private func toggleAlarm() {
        let entityId = "binary_sensor.alarm_sensor"
        viewModel.sendCommandToPhone(entityId: entityId, newState: "toggle")
        alarmOff.toggle() // Update local state
    }
}
