import Foundation
import Starscream  // Import Starscream, a WebSocket client library for swift.
import HassFramework  // Import HassFramework, a framework likely created for interacting with Home Assistant.

// Extend the HassWebSocket class to provide additional functionality specific to setting entity state.
public extension HassWebSocket {

    // Function to set the state of an entity in Home Assistant.
    func setEntityState(entityId: String, newState: String) {
        // Check if the WebSocket is currently connected before trying to send a command.
        guard self.connectionState == .connected else {
            print("WebSocket isn't connected, attempting to reconnect before sending command.")
            // If not connected, attempt to reconnect using a shared WebSocket manager.
            WebSocketManager.shared.connectIfNeeded()
            // Additional logic to retry sending the command after reconnecting can be implemented here.
            return
        }

        // Increment the message ID for every new command sent.
        messageId += 1

        // Log the action of setting the state with the entity ID and the new state.
        print("Setting entity state for entityId:", entityId, ", newState:", newState)

        var domain: String  // Domain in Home Assistant represents a group of related functionalities.
        var service: String // Service in Home Assistant is a callable action.

        // If the entity ID indicates that this is a switch, set the domain and service accordingly.
        if entityId.starts(with: "switch.") {
            domain = "switch"
            service = newState  // For a switch, the newState would typically be 'toggle'.
        } else {
            // For entities that are not switches, we default to using the "homeassistant" domain.
            // We assume that the service name is a combination of "turn_" and the desired state ("on" or "off").
            domain = "homeassistant"
            service = "turn_\(newState)"
        }

        // Construct the command dictionary that will be sent as JSON over the WebSocket.
        let command: [String: Any] = [
            "id": messageId,  // Unique identifier for this command.
            "type": "call_service",  // Indicating that we want to call a Home Assistant service.
            "domain": domain,  // The domain for the service we're calling.
            "service": service,  // The specific service to call.
            "service_data": [
                "entity_id": entityId  // Data provided to the service call, in this case, the entity ID.
            ]
        ]

        // Log the constructed command for debugging purposes.
        print("Constructed command:", command)

        // Try to serialize the command dictionary into JSON data.
        do {
            let data = try JSONSerialization.data(withJSONObject: command, options: [])
            // If successful, attempt to convert the data to a UTF-8 string.
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Sending JSON command:", jsonString)
                // Send the JSON string as a text message over the WebSocket.
                self.sendTextMessage(jsonString)
            } else {
                print("Failed to convert data to string.")
            }
        } catch {
            // If serialization fails, log the error.
            print("Failed to encode message:", error)
        }
    }
}

