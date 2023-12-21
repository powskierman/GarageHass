import Foundation
import Starscream
import HassFramework

public extension HassWebSocket {
    func setEntityState(entityId: String, newState: String) {
        guard isConnected() else {
            // print("WebSocket is not connected.")
            return
        }

        // Increment the message ID for every new command sent.
        messageId += 1

        // Log the action of setting the state with the entity ID and the new state.
        // print("Setting entity state for entityId:", entityId, ", newState:", newState)

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
                // print("Sending JSON command:", jsonString)
                sendTextMessage(jsonString)
            } else {
                // print("Failed to convert data to string.")
            }
        } catch {
            // print("Failed to encode message:", error)
        }
    }
}
