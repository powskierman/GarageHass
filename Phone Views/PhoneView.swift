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
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(garageRestManager.alarmOff ? .teal : .pink)
                }
                .frame(width: 250.0, height: 150.0)
                .padding(EdgeInsets(top: 100, leading: 7, bottom: 0, trailing: 7))
                
                .confirmationDialog("Toggle Alarm", isPresented: $showingAlarmConfirmation) {
                    Button("Confirm", role: .destructive) {
                        let entityId = garageRestManager.alarmOff ? "switch.alarm_on" : "switch.alarm_off"
                        garageRestManager.toggleSwitch(entityId: entityId)
                        garageRestManager.checkStates()
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
        @State private var isPressed = false // New state variable for color change
        
        var body: some View {
            Button(action: {
                // Change color to yellow
                isPressed = true
                
                // Action to toggle door
                let entityId = door == .left ? "switch.left_garage_door" : "switch.right_garage_door"
                garageRestManager.toggleSwitch(entityId: entityId)
                
                // Delay for 500ms before fetching initial state and resetting the color
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isPressed = false
                    garageRestManager.fetchInitialState()
                }
            }) {
                Image(systemName: doorStateImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(isPressed ? .yellow : doorStateColor)
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
}
