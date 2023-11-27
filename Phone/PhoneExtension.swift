import Foundation
import Starscream
import HassFramework

public extension HassWebSocket {
    // Function to set the state of an entity in Home Assistant.
    func setEntityState(entityId: String, newState: String) {
        guard self.connectionState == .connected else {
            print("WebSocket isn't connected, attempting to reconnect before sending command.")
            // This part needs to be updated to use WebSocketManager's connection logic.
            // Assuming WebSocketManager has a method to handle reconnection.
            WebSocketManager.shared.establishConnectionIfNeeded { [weak self] success in
                if success {
                    print("Reconnection successful, attempting to send command again.")
                    self?.setEntityState(entityId: entityId, newState: newState)
                } else {
                    print("Failed to reconnect.")
                }
            }
            return
        }

        // Increment the message ID for every new command sent.
        messageId += 1

        // Log the action of setting the state with the entity ID and the new state.
        print("Setting entity state for entityId:", entityId, ", newState:", newState)

        // Determine domain and service based on entityId
        let (domain, service) = determineDomainAndService(entityId: entityId, newState: newState)

        // Construct and send the command.
        sendCommand(domain: domain, service: service, entityId: entityId)
    }

    private func determineDomainAndService(entityId: String, newState: String) -> (String, String) {
        if entityId.starts(with: "switch.") {
            return ("switch", newState)
        } else {
            return ("homeassistant", "turn_\(newState)")
        }
    }

    private func sendCommand(domain: String, service: String, entityId: String) {
        let command: [String: Any] = [
            "id": messageId,
            "type": "call_service",
            "domain": domain,
            "service": service,
            "service_data": ["entity_id": entityId]
        ]

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
