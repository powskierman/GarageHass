//
//  WatchEntity.swift
//  WatchGarageHass Watch App
//
//  Created by Michel Lapointe on 2023-11-21.
//

import SwiftUI

struct WatchEntityView: View {
    @ObservedObject var viewModel: WatchViewModel
    let entityType: EntityType
    @State private var isEntityActive: Bool = false // Represents the current state of the entity
    @State private var showingConfirmation = false

    var body: some View {
        Button(action: {
            handleButtonPress()
        }) {
            VStack {
                entityImage
                Text(entityLabel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isEntityActive ? Color.pink : Color.teal)
        .confirmationDialog("Confirm Action", isPresented: $showingConfirmation) {
            Button("Confirm", role: .destructive) {
                toggleEntity()
            }
        }
        .onAppear() {
            $viewModel.establishConnectionIfNeeded
        }
    }

    private var entityImage: some View {
        switch entityType {
        case .door:
            return Image(systemName: isEntityActive ? "door.garage.open" : "door.garage.closed")
                      .resizable()
                      .scaledToFit()
        case .alarm:
            return Image(systemName: isEntityActive ? "alarm.waves.left.and.right.fill" : "alarm")
                      .resizable()
                      .scaledToFit()
        }
    }

    private var entityLabel: String {
        switch entityType {
        case .door(let door):
            return door == .left ? "Left Door" : "Right Door"
        case .alarm:
            return "Alarm"
        }
    }

    private func handleButtonPress() {
        switch entityType {
        case .alarm:
            showingConfirmation = true
        default:
            toggleEntity()
        }
    }

    private func toggleEntity() {
        let entityId: String
        switch entityType {
        case .door(let door):
            entityId = door == .left ? "switch.left_garage_door" : "switch.right_garage_door"
        case .alarm:
            entityId = "switch.alarm_sensor"
        }

        viewModel.sendCommandToPhone(entityId: entityId, newState: "toggle")
        print("Sent command to phone: \(entityId)")
        isEntityActive.toggle() // Update local state
    }
}
