// GarageView.swift

import SwiftUI
import HassFramework

struct GarageView: View {
    @ObservedObject var viewModel = GarageViewModel()
    
    var body: some View {
        VStack {
            ConnectionStatusBar(message: "Connection Status", connectionState: $viewModel.connectionState)
                .id(viewModel.connectionState)
            
            VStack(spacing: 50) {
                HStack {
                    GarageDoorButton(isClosed: $viewModel.leftDoorClosed, action: {
                        viewModel.handleDoorAction(entityId: "switch.newgarage_left_garage_door")
                    })

                    GarageDoorButton(isClosed: $viewModel.rightDoorClosed, action: {
                        viewModel.handleDoorAction(entityId: "switch.newgarage_right_garage_door")
                    })
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
                }

                Button(action: {
//                    viewModel.handleAlarmAction()
                }) {
                    Image(systemName: "alarm.waves.left.and.right")
                        .resizable()
                        .frame(width: 250.0, height: 150.0)
                        .foregroundColor(viewModel.alarmOff ? .teal : .pink)
                }
                .padding(EdgeInsets(top: 100, leading: 7, bottom: 0, trailing: 7))
            }
        }
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
                .frame(width: 170.0, height: 170.0)
                .foregroundColor(isClosed ? .teal : .pink)
        }
    }
}

struct GarageView_Previews: PreviewProvider {
    static var previews: some View {
        GarageView()
    }
}
