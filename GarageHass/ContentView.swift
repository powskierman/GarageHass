import SwiftUI
import Starscream
import HassFramework


struct ContentView: View {
    @ObservedObject public var websocketVM = WebSocketManager.shared
    @State private var showEventsList: Bool = false
    
    @State var leftDoorClosed: Bool = true
    @State var rightDoorClosed: Bool = false
    @State var alarmOff: Bool = true
    
    var body: some View {
        VStack {
            ConnectionStatusBar(message: "Connection Status", isConnected: websocketVM.connectionState == .connected)

            VStack(spacing: 50) {
                HStack {
                    
                    Button(action: {
                        websocketVM.websocket.setEntityState(entityId: "switch.newgarage_left_garage_door", newState: "toggle")
                        print("Button pressed!")
                    })
{
                        Image(systemName: "door.garage.closed")
                            .resizable()
                            .frame(width: 170.0, height: 170.0)
                            .foregroundColor(websocketVM.leftDoorClosed == true ? .teal : .pink)
                    }

                    Button(action: { }) {
                        Image(systemName: "door.garage.open")
                            .resizable()
                            .frame(width: 170.0, height: 170.0)
                            .foregroundColor(rightDoorClosed == true ? .teal : .pink)
                    }
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
                }
                .onAppear() {
                    // Establish WebSocket connection
                    websocketVM.connect()

                    // Start listening to events to reflect the door status
                    websocketVM.subscribeToEvents()
                }

                Button(action: { }) {
                    Image(systemName: "alarm.waves.left.and.right")
                        .resizable()
                        .frame(width: 250.0, height: 150.0)
                        .foregroundColor(alarmOff == true ? .teal : .pink)
                }
                .padding(EdgeInsets(top: 100, leading: 7, bottom: 0, trailing: 7))
            }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
