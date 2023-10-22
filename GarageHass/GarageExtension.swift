import Foundation
import Starscream
import HassFramework

public extension HassWebSocket {

    func setEntityState(entityId: String, newState: String) {
        guard self.connectionState == .connected else {
            print("WebSocket isn't connected, attempting to reconnect before sending command.")
            WebSocketManager.shared.connectIfNeeded()
            // Logic to resend command after reconnect can be added here
            return
        }

        messageId += 1

        print("Setting entity state for entityId:", entityId, ", newState:", newState)

        var domain: String
        var service: String

        if entityId.starts(with: "switch.") {
            domain = "switch"
            service = newState  // newState would be 'toggle' for a switch
        } else {
            // Handle other entity types as needed
            domain = "homeassistant"
            service = "turn_\(newState)"
        }

        let command: [String: Any] = [
            "id": messageId,
            "type": "call_service",
            "domain": domain,
            "service": service,
            "service_data": [
                "entity_id": entityId
            ]
        ]

        print("Constructed command:", command)

        do {
            let data = try JSONSerialization.data(withJSONObject: command, options: [])
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Sending JSON command:", jsonString)
                self.sendTextMessage(jsonString)
            } else {
                print("Failed to convert data to string.")
            }
        } catch {
            print("Failed to encode message:", error)
        }
    }
}
