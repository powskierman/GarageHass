import SwiftUI
import HassFramework  // Import the SwiftUI for UI components and HassFramework for Home Assistant support.

struct PhoneView: View {
    @EnvironmentObject var webSocketManager: WebSocketManager

    // A state variable to control the display of the alarm confirmation dialog.
    @State private var showingAlarmConfirmation = false

    var body: some View {
        VStack {
            // Display the connection status bar at the top of the view.
            ConnectionStatusBar(message: "Connection Status", connectionState: $webSocketManager.connectionState)
                .id(webSocketManager.connectionState) // The id here is used to force the view to update when the connection state changes.
            
            // Vertical stack for the buttons with spacing.
            VStack(spacing: 50) {
                // Horizontal stack for garage door buttons.
                HStack {
                    // Garage door button for the left door.
                    GarageDoorButton(isClosed: $webSocketManager.leftDoorClosed, action: {
                        // Triggers an action in the view model to handle the left door state change.
                        webSocketManager.handleEntityAction(entityId: "switch.left_garage_door")
                    })
                    
                    // Garage door button for the right door.
                    GarageDoorButton(isClosed: $webSocketManager.rightDoorClosed, action: {
                        // Triggers an action in the view model to handle the right door state change.
                        webSocketManager.handleEntityAction(entityId: "switch.right_garage_door")
                    })
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0)) // Add padding to the right button for visual separation.
                }
                
                // Button to toggle the alarm.
                Button(action: {
                    // When button is pressed, it shows a confirmation dialog.
                    self.showingAlarmConfirmation = true
                }) {
                    // The image changes depending on whether the alarm is off or on.
                    Image(systemName: webSocketManager.alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
                        .resizable()
                        .frame(width: webSocketManager.alarmOff ? 150.0 : 250.0, height: webSocketManager.alarmOff ? 150.0 : 150.0)
                        .foregroundColor(webSocketManager.alarmOff ? .teal : .pink)
                }
                .padding(EdgeInsets(top: 100, leading: 7, bottom: 0, trailing: 7)) // Add padding around the alarm button.
                .confirmationDialog("Toggle Alarm", isPresented: $showingAlarmConfirmation) {
                    Button("Confirm", role: .destructive) {
                        let entityIdToToggle = webSocketManager.alarmOff ? "switch.alarm_on" : "switch.alarm_off"
                        webSocketManager.handleEntityAction(entityId: entityIdToToggle)
                    }
                }
            }
        }
        .onAppear() {
            webSocketManager.establishConnectionIfNeeded()
        }
    }
}

// Define a view for the garage door button.
struct GarageDoorButton: View {
    @Binding var isClosed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isClosed ? "door.garage.closed" : "door.garage.open")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(isClosed ? .teal : .pink)
        }
        .frame(width: 170.0, height: 170.0)
    }
}

// Define a view for the alarm button.
struct AlarmButton: View {
    @Binding var isAlarmOn: Bool
    let action: () -> Void
    @State private var showingConfirmation = false

    var body: some View {
        Button(action: { showingConfirmation = true }) {
            Image(systemName: isAlarmOn ? "alarm.waves.left.and.right.fill" : "alarm")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(isAlarmOn ? .pink : .teal)
        }
        .frame(width: 250.0, height: 150.0)
        .confirmationDialog(
            "Alarm Confirmation",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Confirm", role: .destructive, action: action)
            Button("Cancel", role: .cancel) {}
        }
    }
}

// Provide a preview of the GarageView.
struct GarageView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneView().environmentObject(WebSocketManager(websocket: WebSocketManager.shared.websocket))
    }
}
