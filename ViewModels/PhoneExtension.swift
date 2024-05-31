import Foundation
import Starscream
import HassFramework

public extension HassWebSocket {
    func setEntityState(entityId: String, newState: String) {
        // Ensure the baseURL and authToken are correctly initialized and used
        guard let secretsPath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let secrets = NSDictionary(contentsOfFile: secretsPath) as? [String: Any],
              let serverURLString = secrets["RESTURL"] as? String,
              let authToken = secrets["authToken"] as? String,
              let baseURL = URL(string: serverURLString) else {
            print("Invalid or missing configuration in Secrets.plist.")
            return
        }

        // Initialize restClient with the loaded secrets
        let restClient = HassRestClient(baseURL: baseURL, authToken: authToken)
        
        // Determine domain and service based on entityId
        let (_, service) = determineDomainAndService(entityId: entityId, newState: newState)

        // Assuming the command's data requires just the entity_id for this operation
        let commandData = ["entity_id": entityId]

        // Create an instance of DeviceCommand, including the data parameter
        let command = HassRestClient.DeviceCommand(service: service, entityId: entityId, data: commandData)

        // Use restClient to send the command
        restClient.sendCommandToDevice(deviceId: entityId, command: command) { result in
            // Handle result: success or error
            switch result {
            case .success:
                print("State set successfully")
            case .failure(let error):
                print("Failed to set state: \(error.localizedDescription)")
            }
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
