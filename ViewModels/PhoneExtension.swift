import Foundation
import Starscream
import HassFramework

public extension HassWebSocket {
    func setEntityState(entityId: String, newState: String) {
         var restClient: HassRestClient?
         // Determine domain and service based on entityId
         let (_, service) = determineDomainAndService(entityId: entityId, newState: newState)

         // Assuming the command's data requires just the entity_id for this operation
         let commandData = ["entity_id": entityId]

         // Create an instance of DeviceCommand, including the data parameter
         // Note: Ensure the data parameter matches the expected format for the command
         // If your DeviceCommand's data property expects an Encodable or specifically formatted type, adjust accordingly
        let command = HassRestClient.DeviceCommand(service: service, entityId: entityId, data: commandData)

        restClient?.sendCommandToDevice(deviceId: entityId, command: command) { result in
             // Handle result: success or error
         }
     }

     private func determineDomainAndService(entityId: String, newState: String) -> (String, String) {
         // Implementation to determine the domain and service based on entityId and newState
         // Placeholder implementation, adjust as needed
         return ("domain", "service")
     }
    
//    func setEntityState(entityId: String, newState: String) {
//        guard isConnected() else {
//            // print("WebSocket is not connected.")
//            return
//        }
//
//        // Increment the message ID for every new command sent.
//        messageId += 1
//
//        // Log the action of setting the state with the entity ID and the new state.
//        // print("Setting entity state for entityId:", entityId, ", newState:", newState)
//
//        // Determine domain and service based on entityId
//        let (domain, service) = determineDomainAndService(entityId: entityId, newState: newState)
//
//        // Construct and send the command.
//        sendCommand(domain: domain, service: service, entityId: entityId)
//    }

//    private func determineDomainAndService(entityId: String, newState: String) -> (String, String) {
//        if entityId.starts(with: "switch.") {
//            return ("switch", newState)
//        } else {
//            return ("homeassistant", "turn_\(newState)")
//        }
//    }

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
