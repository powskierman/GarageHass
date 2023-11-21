//
//  WatchDoorView.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2023-11-16.
//

import SwiftUI

struct WatchDoorView: View {
    enum Door {
        case left
        case right
    }
    var viewModel: WatchViewModel

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
        print("Sent door command to phone: \(entityId)")
        //isClosed.toggle() // Update local state
 //       viewModel.handleEntityAction(entityId: "switch.left_garage_door")
    }
}
