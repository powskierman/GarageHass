import SwiftUI
import Starscream
import HassFramework
import Combine

struct GarageView: View {
    @ObservedObject public var websocketVM = WebSocketManager.shared
    
    @State private var showEventsList: Bool = false
    @State var leftDoorClosed: Bool = true
    @State var rightDoorClosed: Bool = false
    @State var alarmOff: Bool = true
    
    var body: some View {
        VStack {
            ConnectionStatusBar(message: "Connection Status", isConnected: websocketVM.websocket.connectionState == .connected)
                .id(websocketVM.websocket.connectionState)
                .onReceive(Just(websocketVM.websocket.connectionState)) { newState in
                    print("Current connection state: \(newState)")
                    if newState == .connected {
                        print("WebSocket is now connected.")
                    } else {
                        print("WebSocket is not connected.")
                    }
                }

            VStack(spacing: 50) {
                HStack {
                    
                    Button(action: {
                        websocketVM.websocket.setEntityState(entityId: "switch.newgarage_left_garage_door", newState: "toggle")
                        print("Button pressed!")
                    })
{
                        Image(systemName: leftDoorClosed ? "door.garage.closed" : "door.garage.open")
                            .resizable()
                            .frame(width: 170.0, height: 170.0)
                            .foregroundColor(leftDoorClosed ? .teal : .pink)
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
                    websocketVM.websocket.connect()

                    // Start listening to events to reflect the door status
                    websocketVM.websocket.subscribeToEvents()

                    // Handle state change events
                    websocketVM.websocket.onEventReceived = { event in
                        if let data = event.data(using: .utf8),
                           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                           let message = jsonObject as? [String: Any],
                           let eventType = message["event_type"] as? String, eventType == "state_changed",
                           let eventData = message["data"] as? [String: Any],
                           let entityId = eventData["entity_id"] as? String, entityId == "binary_sensor.newgarage_left_door_sensor",
                           let newStateData = eventData["new_state"] as? [String: Any],
                           let newState = newStateData["state"] as? String {
                           
                            self.leftDoorClosed = (newState == "closed")
                        }
                    }
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
        GarageView()
    }
}
