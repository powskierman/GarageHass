import SwiftUI

struct WatchEntityView: View {
    @ObservedObject var viewModel: WatchViewModel
    let entityType: EntityType

    var body: some View {
        Button(action: handleButtonPress) {
            VStack {
                entityImage
                Text(entityLabel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(entityBackgroundColor)
    }

    private var entityImage: some View {
        switch entityType {
        case .door(let doorType):
            let isClosed = doorType == .left ? viewModel.leftDoorClosed : viewModel.rightDoorClosed
            return Image(systemName: isClosed ? "door.garage.closed" : "door.garage.open")
                .resizable()
                .scaledToFit()
        case .alarm:
            return Image(systemName: viewModel.alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
                .resizable()
                .scaledToFit()
        }
    }

    private var entityLabel: String {
        switch entityType {
        case .door(let doorType):
            return doorType == .left ? "Left Door" : "Right Door"
        case .alarm:
            return "Alarm"
        }
    }

    private var entityBackgroundColor: Color {
        switch entityType {
        case .door(let doorType):
            let isClosed = doorType == .left ? viewModel.leftDoorClosed : viewModel.rightDoorClosed
            return isClosed ? Color.teal : Color.pink
        case .alarm:
            return viewModel.alarmOff ? Color.teal : Color.pink
        }
    }

    private func handleButtonPress() {
        switch entityType {
        case .door(let doorType):
            let entityId = doorType == .left ? "switch.left_garage_door" : "switch.right_garage_door"
            viewModel.sendCommandToPhone(entityId: entityId, newState: "toggle")
        case .alarm:
            let entityId = "switch.alarm"
            let newState = viewModel.alarmOff ? "on" : "off"
            viewModel.sendCommandToPhone(entityId: entityId, newState: newState)
        }
    }
}
