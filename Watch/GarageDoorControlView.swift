//
//  GarageDoorControlView.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-16.
//

import SwiftUI

struct GarageDoorControlView: View {
    enum Door {
        case left
        case right
    }
    var viewModel: GarageDoorViewModel

    var door: Door
    @State private var isClosed: Bool = true // This state can be modified based on actual door state if needed

    var body: some View {
        Button(action: {
            toggleDoor()
        }) {
            VStack {
                Image(systemName: isClosed ? "door.garage.closed" : "door.garage.open")
                    .resizable()
                    .scaledToFit()
                Text(door == .left ? "Left Door" : "Right Door")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isClosed ? Color.teal : Color.pink)
    }

    private func toggleDoor() {
        let entityId = door == .left ? "switch.left_garage_door" : "switch.right_garage_door"
        viewModel.sendCommandToPhone(entityId: entityId, newState: "toggle")
        isClosed.toggle() // Update local state
    }
}
