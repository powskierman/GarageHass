import SwiftUI
import Combine

struct PhoneView: View {
    @EnvironmentObject var garageRestManager: GarageRestManager
    @State private var cancellable: AnyCancellable?
    @State private var showingAlarmConfirmation = false
    @State private var showingErrorAlert = false
    
    var body: some View {
        VStack {
            ConnectionStatusBar(message: "Connection Status")
            
            VStack(spacing: 50) {
                HStack {
                    GarageDoorButton(door: .left)
                        .environmentObject(garageRestManager)
                    
                    GarageDoorButton(door: .right)
                        .environmentObject(garageRestManager)
                }
                
                Button(action: {
                    self.showingAlarmConfirmation = true
                }) {
                    Image(systemName: garageRestManager.alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
                        .resizable()
                        .frame(width: 150.0, height: 150.0)
                        .foregroundColor(garageRestManager.alarmOff ? .teal : .pink)
                }
                .padding(EdgeInsets(top: 100, leading: 7, bottom: 0, trailing: 7))
            }
            .confirmationDialog("Toggle Alarm", isPresented: $showingAlarmConfirmation) {
                Button("Confirm", role: .destructive) {
                    let newState = garageRestManager.alarmOff ? "on" : "off"
                    let entityIdToToggle = "alarm_control_panel.your_alarm_entity" // replace with your actual entity ID
                    garageRestManager.handleEntityAction(entityId: entityIdToToggle, newState: newState)
                }
            }
            
            if let error = garageRestManager.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .alert("Connection Error", isPresented: $showingErrorAlert, actions: {
            Button("Retry") {
                // Implement retry logic if necessary
            }
        }, message: {
            if let error = garageRestManager.error {
                Text(error.localizedDescription)
            }
        })
        .onChange(of: garageRestManager.hasErrorOccurred) { _, _ in
            showingErrorAlert = garageRestManager.hasErrorOccurred
        }
        .onAppear() {
            garageRestManager.fetchInitialState()
        }
    }
}

struct GarageDoorButton: View {
    @EnvironmentObject var garageRestManager: GarageRestManager
    var door: Door

    var body: some View {
        Button(action: {
            // The script entity ID should match what is configured in Home Assistant
            let scriptEntityId = door == .left ? "script.toggle_left_door" : "script.toggle_right_door"
            garageRestManager.handleScriptAction(entityId: scriptEntityId)
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
            return garageRestManager.leftDoorClosed ? "door.garage.closed" : "door.garage.open"
        case .right:
            return garageRestManager.rightDoorClosed ? "door.garage.closed" : "door.garage.open"
        }
    }

    private var doorStateColor: Color {
        switch door {
        case .left:
            return garageRestManager.leftDoorClosed ? .teal : .pink
        case .right:
            return garageRestManager.rightDoorClosed ? .teal : .pink
        }
    }
}

// Provide a preview of the PhoneView.
struct PhoneView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneView().environmentObject(GarageRestManager.shared)
    }
}
