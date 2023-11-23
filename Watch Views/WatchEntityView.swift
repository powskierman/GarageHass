import SwiftUI

struct WatchEntityView: View {
    @ObservedObject var viewModel: WatchViewModel
    let entityType: EntityType

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
        .background(entityBackgroundColor)
        // ... other view modifiers or UI elements
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
        // Implementation for handling button press
        // Likely involves calling `viewModel.sendCommandToPhone`
        // with appropriate entityId and newState
    }
}
