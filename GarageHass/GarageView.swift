import SwiftUI
import HassFramework

struct GarageView: View {
    @ObservedObject var viewModel = GarageViewModel()
    @State private var showingAlarmConfirmation = false

    var body: some View {
        VStack {
            ConnectionStatusBar(message: "Connection Status", connectionState: $viewModel.connectionState)
                .id(viewModel.connectionState)

            VStack(spacing: 50) {
                HStack {
                    GarageDoorButton(isClosed: $viewModel.leftDoorClosed, action: {
                        viewModel.handleEntityAction(entityId: "switch.left_garage_door")
                    })

                    GarageDoorButton(isClosed: $viewModel.rightDoorClosed, action: {
                        viewModel.handleEntityAction(entityId: "switch.right_garage_door")
                    })
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
                }

                Button(action: {
                     self.showingAlarmConfirmation = true
                 }) {
                     Image(systemName: viewModel.alarmOff ? "alarm" : "alarm.waves.left.and.right.fill")
                         .resizable()
                         .frame(width: 250.0, height: 150.0)
                         .foregroundColor(viewModel.alarmOff ? .teal : .pink)
                 }
                 .padding(EdgeInsets(top: 100, leading: 7, bottom: 0, trailing: 7))
                 .confirmationDialog("Toggle Alarm", isPresented: $showingAlarmConfirmation) {
                     Button("Confirm", role: .destructive) {
                         viewModel.handleAlarmToggleConfirmed()
                     }
                 }
             }
         }
//                AlarmButton(isAlarmOn: $viewModel.alarmOff, action: {
//                    viewModel.handleAlarmAction()
//                })
//                .padding(EdgeInsets(top: 100, leading: 7, bottom: 0, trailing: 7))
//            }
//        }
        .onAppear() {
            viewModel.establishConnectionIfNeeded()
        }
    }
}

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

struct AlarmButton: View {
    @Binding var isAlarmOn: Bool
    let action: () -> Void
    @State private var showingConfirmation = false

    var body: some View {
        Button(action: {
            showingConfirmation = true
        }) {
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

struct GarageView_Previews: PreviewProvider {
    static var previews: some View {
        GarageView()
    }
}
