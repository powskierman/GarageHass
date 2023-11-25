import SwiftUI
import HassFramework  // Import the SwiftUI for UI components and HassFramework for Home Assistant support.

// Define a view representing the Garage interface.
struct PhoneView: View {
//    // Observe changes in the GarageViewModel to update the UI accordingly.
//    @ObservedObject var viewModel = PhoneViewModel(websocket: WebSocketManager.shared.websocket)
    @ObservedObject var viewModel: PhoneViewModel

     // Ensure viewModel is initialized correctly
     init() {
         _viewModel = ObservedObject(initialValue: PhoneViewModel(websocket: WebSocketManager.shared.websocket))
     }
    
    // A state variable to control the display of the alarm confirmation dialog.
    @State private var showingAlarmConfirmation = false

    // Define the body of the view.
    var body: some View {
        VStack {
            // Display the connection status bar at the top of the view.
            ConnectionStatusBar(message: "Connection Status", connectionState: $viewModel.connectionState)
                .id(viewModel.connectionState) // The id here is used to force the view to update when the connection state changes.
            
            // Vertical stack for the buttons with spacing.
            VStack(spacing: 50) {
                // Horizontal stack for garage door buttons.
                HStack {
                    // Garage door button for the left door.
                    GarageDoorButton(isClosed: $viewModel.leftDoorClosed, action: {
                        // Triggers an action in the view model to handle the left door state change.
                        viewModel.handleEntityAction(entityId: "switch.left_garage_door")
                    })
                    
                    // Garage door button for the right door.
                    GarageDoorButton(isClosed: $viewModel.rightDoorClosed, action: {
                        // Triggers an action in the view model to handle the right door state change.
                        viewModel.handleEntityAction(entityId: "switch.right_garage_door")
                    })
                    // Add padding to the right button for visual separation.
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
                }
                
                // Button to toggle the alarm.
                Button(action: {
                    // When button is pressed, it shows a confirmation dialog.
                    self.showingAlarmConfirmation = true
                }) {
                    // The image changes depending on whether the alarm is off or on.
                    Image(systemName: viewModel.alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
                        .resizable()
                        .frame(width: viewModel.alarmOff ? 150.0 : 250.0, height: viewModel.alarmOff ? 150.0 : 150.0)
                        .foregroundColor(viewModel.alarmOff ? .teal : .pink)
                }
                // Add padding around the alarm button.
                .padding(EdgeInsets(top: 100, leading: 7, bottom: 0, trailing: 7))
                // Define the confirmation dialog for toggling the alarm.
                .confirmationDialog("Toggle Alarm", isPresented: $showingAlarmConfirmation) {
                    Button("Confirm", role: .destructive) {
                        // Calls the method to handle confirmed alarm action in the view model.
                        viewModel.handleAlarmActionConfirmed()
                    }
                }
            }
        }
        // When the view appears, attempt to establish a connection if needed.
        .onAppear() {
            viewModel.establishConnectionIfNeeded()
        }
    }
}

// Define a view for the garage door button.
struct GarageDoorButton: View {
    // Bind to a boolean to know if the door is closed.
    @Binding var isClosed: Bool
    // Define an action to perform when the button is pressed.
    let action: () -> Void

    // Define the body for the garage door button.
    var body: some View {
        Button(action: action) {
            // Change the image depending on the door state.
            Image(systemName: isClosed ? "door.garage.closed" : "door.garage.open")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(isClosed ? .teal : .pink)
        }
        .frame(width: 170.0, height: 170.0) // Set the frame for the button.
    }
}

// Define a view for the alarm button.
struct AlarmButton: View {
    // Bind to a boolean to know if the alarm is on.
    @Binding var isAlarmOn: Bool
    // Action to perform when the button is pressed.
    let action: () -> Void
    // State to control showing of the confirmation dialog.
    @State private var showingConfirmation = false

    // Define the body for the alarm button.
    var body: some View {
        Button(action: {
            // When the button is pressed, show the confirmation dialog.
            showingConfirmation = true
        }) {
            // Change the image depending on the alarm state.
            Image(systemName: isAlarmOn ? "alarm.waves.left.and.right.fill" : "alarm")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(isAlarmOn ? .pink : .teal)
        }
        .frame(width: 250.0, height: 150.0) // Set the frame for the button.
        // Present a confirmation dialog when attempting to toggle the alarm state.
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
        PhoneView()
    }
}

