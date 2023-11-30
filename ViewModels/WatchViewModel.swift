import Foundation
import WatchConnectivity

class WatchViewModel: NSObject, ObservableObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
          // When the session is activated, fetch the initial state
          if activationState == .activated {
              requestInitialState()
          }
      }

      private func requestInitialState() {
          // Check if the session is reachable before sending a message
          if WCSession.default.isReachable {
              print("Requesting initial state from iPhone app")
              let message = ["request": "initialState"]
              WCSession.default.sendMessage(message, replyHandler: { response in
                  // Process the response here
                  self.processInitialStateResponse(response)
              }, errorHandler: { error in
                  print("Error requesting initial state: \(error.localizedDescription)")
              })
          }
      }

      private func processInitialStateResponse(_ response: [String: Any]) {
          DispatchQueue.main.async {
              if let leftDoorClosedValue = response["leftDoorClosed"] as? Bool {
                  self.leftDoorClosed = leftDoorClosedValue
              }
              if let rightDoorClosedValue = response["rightDoorClosed"] as? Bool {
                  self.rightDoorClosed = rightDoorClosedValue
              }
              if let alarmOffValue = response["alarmOff"] as? Bool {
                  self.alarmOff = alarmOffValue
              }
          }
      }

    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true

    override init() {
        super.init()
        print("Running setupWatchConnectivity")
        setupWatchConnectivity()
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("Watch Connectivity setup initiated.")
        } else {
            print("Watch Connectivity not supported on this device.")
        }
    }

    func sendCommandToPhone(entityId: String, newState: String) {
        print("Attempting to send command to iPhone: \(entityId), newState: \(newState)")
        if WCSession.default.isReachable {
            print("WCSession is reachable. Sending message.")
            let message = ["entityId": entityId, "newState": newState]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message to phone: \(error.localizedDescription)")
            }
        } else {
            print("WCSession is not reachable at the moment.")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message from phone:", message)
        DispatchQueue.main.async {
            if let entityId = message["entityId"] as? String,
               let newState = message["newState"] as? String {
                self.updateStateBasedOnMessage(entityId: entityId, newState: newState)
            }
        }
    }

    private func updateStateBasedOnMessage(entityId: String, newState: String) {
        print("Updating state based on message - Entity ID: \(entityId), New State: \(newState)")
        DispatchQueue.main.async {
            switch entityId {
            case "binary_sensor.left_door_sensor":
                print("Updating Left Door Sensor State")
                // Set the state of the left garage door
                self.leftDoorClosed = (newState == "closed") // Set based on the received state
            case "binary_sensor.right_door_sensor":
                print("Updating Right Door Sensor State")
                // Set the state of the right garage door
                self.rightDoorClosed = (newState == "closed") // Set based on the received state
            case "binary_sensor.alarm_sensor":
                print("Updating Alarm Sensor State")
                // Set the alarm state
                self.alarmOff = (newState == "off") // Set based on the received state
            default:
                print("Unknown entity ID: \(entityId)")
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("SessionDelegator: WCSession reachability changed. Is now reachable: \(session.isReachable)")
    }
}
