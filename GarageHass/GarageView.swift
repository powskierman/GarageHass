import SwiftUI
import HassFramework

struct GarageView: View {
    @ObservedObject var viewModel = GarageViewModel()
    
    var body: some View {
        VStack(spacing: 50) {
            HStack {
                Button(action: {
                    viewModel.handleDoorAction(entityId: "switch.newgarage_left_garage_door")
                    print("Left door button pressed!")
                }) {
                    Image(systemName: viewModel.leftDoorClosed ? "door.garage.closed" : "door.garage.open")
                        .resizable()
                        .frame(width: 170.0, height: 170.0)
                        .foregroundColor(viewModel.leftDoorClosed ? .teal : .pink)
                }
                
                Button(action: {
                    viewModel.handleDoorAction(entityId: "switch.newgarage_right_garage_door")
                    print("Right door button pressed!")
                }) {
                    Image(systemName: viewModel.rightDoorClosed ? "door.garage.closed" : "door.garage.open")
                        .resizable()
                        .frame(width: 170.0, height: 170.0)
                        .foregroundColor(viewModel.rightDoorClosed ? .teal : .pink)
                }
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
            }
        }
        .onAppear() {
            viewModel.establishConnectionIfNeeded()
        }
    }
}

struct GarageView_Previews: PreviewProvider {
    static var previews: some View {
        GarageView()
    }
}
