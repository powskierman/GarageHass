import SwiftUI
import HassFramework  // Import the SwiftUI for UI components and HassFramework for Home Assistant support.

struct PhoneView: View {
    @EnvironmentObject var garageSocketManager: GarageSocketManager
    @Environment(\.scenePhase) private var scenePhase
    
    // A state variable to control the display of the alarm confirmation dialog.
    @State private var showingAlarmConfirmation = false
    @State private var showingErrorAlert = false
    
    var body: some View {
        VStack {
            // Display the connection status bar at the top of the view.
            ConnectionStatusBar(message: "Connection Status", connectionState: $garageSocketManager.connectionState)
                .id(garageSocketManager.connectionState) // The id here is used to force the view to update when the connection state changes.
            
            // Vertical stack for the buttons with spacing.
            VStack(spacing: 50) {
                // Horizontal stack for garage door buttons.
                HStack {
                    // Garage door button for the left door.
                    GarageDoorButton(door: .left)
                        .environmentObject(garageSocketManager)
                    
                    // Garage door button for the right door.
                    GarageDoorButton(door: .right)
                        .environmentObject(garageSocketManager)
                }
                
                // Button to toggle the alarm.
                Button(action: {
                    // When button is pressed, it shows a confirmation dialog.
                    self.showingAlarmConfirmation = true
                }) {
                    // The image changes depending on whether the alarm is off or on.
                    Image(systemName: garageSocketManager.alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
                        .resizable()
                        .frame(width: garageSocketManager.alarmOff ? 150.0 : 250.0, height: garageSocketManager.alarmOff ? 150.0 : 150.0)
                        .foregroundColor(garageSocketManager.alarmOff ? .teal : .pink)
                }
                .padding(EdgeInsets(top: 100, leading: 7, bottom: 0, trailing: 7)) // Add padding around the alarm button.
            }
            .confirmationDialog("Toggle Alarm", isPresented: $showingAlarmConfirmation) {
                Button("Confirm", role: .destructive) {
                    let entityIdToToggle = garageSocketManager.alarmOff ? "switch.alarm_on" : "switch.alarm_off"
                    let command = "{\"entity_id\": \"\(entityIdToToggle)\"}" // Construct your command string
                    garageSocketManager.handleEntityAction(entityId: entityIdToToggle)
                    print("Alarm toggle command sent!")
                }
            }
            
            if let error = garageSocketManager.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .alert("Connection Error", isPresented: $showingErrorAlert, actions: {
            Button("Retry") {
                garageSocketManager.establishConnectionIfNeeded()
            }
        }, message: {
            if let error = garageSocketManager.error {
                Text(error.localizedDescription)
            }
        })
        .onChange(of: garageSocketManager.hasErrorOccurred) { _, _ in
            showingErrorAlert = garageSocketManager.hasErrorOccurred
        }
        .onAppear() {
            garageSocketManager.establishConnectionIfNeeded()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                print("App is active. Attempting to force reconnect...")
                garageSocketManager.forceReconnect()
            case .background:
                print("App is in background")
                WebSocketManager.shared.disconnectIfNeeded()
            default:
                break
            }
        }
    }
}

// Define a view for the garage door button.
struct GarageDoorButton: View {
    @EnvironmentObject var webSocketManager: GarageSocketManager
    var door: Door

    var body: some View {
        Button(action: {
            switch door {
            case .left:
                webSocketManager.handleEntityAction(entityId: "switch.left_garage_door")
            case .right:
                webSocketManager.handleEntityAction(entityId: "switch.right_garage_door")
            }
        }) {
            Image(systemName: doorStateImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(doorStateColor)
        }
        .frame(width: 170.0, height: 170.0)
    }

    private var doorStateImage: String {
        switch door {
        case .left:
            return webSocketManager.leftDoorClosed ? "door.garage.closed" : "door.garage.open"
        case .right:
            return webSocketManager.rightDoorClosed ? "door.garage.closed" : "door.garage.open"
        }
    }

    private var doorStateColor: Color {
        switch door {
        case .left:
            return webSocketManager.leftDoorClosed ? .teal : .pink
        case .right:
            return webSocketManager.rightDoorClosed ? .teal : .pink
        }
    }
}


// Define a view for the alarm button.
struct AlarmButton: View {
    @EnvironmentObject var webSocketManager: GarageSocketManager
    @State private var showingConfirmation = false

    var body: some View {
        Button(action: {
            showingConfirmation = true
        }) {
            Image(systemName: webSocketManager.alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(webSocketManager.alarmOff ? .teal : .pink)
        }
        .frame(width: 250.0, height: 150.0)
        .confirmationDialog(
            "Alarm Confirmation",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Confirm", role: .destructive) {
                let entityIdToToggle = webSocketManager.alarmOff ? "switch.alarm_on" : "switch.alarm_off"
                webSocketManager.handleEntityAction(entityId: entityIdToToggle)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// Provide a preview of the GarageView.
struct GarageView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneView().environmentObject(GarageSocketManager.shared)
    }
}
