import Foundation
import Combine
import HassFramework

class GarageRestManager: ObservableObject {
    static let shared = GarageRestManager()
    
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var error: Error?
    @Published var hasErrorOccurred: Bool = false
    @Published var lastCallStatus: CallStatus = .pending

    private var cancellables = Set<AnyCancellable>()
    private var initializationFailed = false

    // Properties for baseURL and authToken
    private let baseURL: URL
    private let authToken: String

    private init() {
        // Load baseURL and authToken from Secrets.plist
        guard let secretsPath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let secrets = NSDictionary(contentsOfFile: secretsPath) as? [String: Any],
              let serverURLString = secrets["RESTURL"] as? String,
              let authToken = secrets["authToken"] as? String,
              let baseURL = URL(string: serverURLString) else {
            fatalError("Invalid or missing configuration in Secrets.plist.")
        }
        
        self.baseURL = baseURL
        self.authToken = authToken

        print("[GarageRestManager] Initialized with REST client.")
    }
    
    func fetchInitialState() {
        print("[GarageRestManager] Fetching initial state.")
        lastCallStatus = .pending
        let sensors = ["binary_sensor.left_door_sensor", "binary_sensor.right_door_sensor", "binary_sensor.alarm_sensor"]
        sensors.forEach { entityId in
            HassRestClient(baseURL: baseURL, authToken: authToken).fetchState(entityId: entityId) { [weak self] result in
                DispatchQueue.main.async {
                    print("[GarageRestManager] REST call completed for entityId: \(entityId).")
                    switch result {
                    case .success(let entity):
                        print("[GarageRestManager] Success fetching state for \(entityId): \(entity)")
                        self?.lastCallStatus = .success
                        self?.processState(entity)
                        self?.error = nil
                        self?.hasErrorOccurred = false
                    case .failure(let error):
                        print("[GarageRestManager] Failure fetching state for \(entityId): \(error)")
                        self?.lastCallStatus = .failure
                        self?.error = error
                        self?.hasErrorOccurred = true
                    }
                }
            }
        }
    }

    private func processState(_ entity: HAEntity) {
        print("[GarageRestManager] Processing state for entity: \(entity)")
        switch entity.entityId {
        case "binary_sensor.left_door_sensor":
            leftDoorClosed = entity.state == "off"
        case "binary_sensor.right_door_sensor":
            rightDoorClosed = entity.state == "off"
        case "binary_sensor.alarm_sensor":
            alarmOff = entity.state == "off"
        default:
            print("[GarageRestManager] State changed or unprocessed entity: \(entity.entityId)")
            break
        }
    }

//    func handleEntityAction(entityId: String, newState: String) {
//        print("[GarageRestManager] Handling entity action for \(entityId), new state: \(newState)")
//        lastCallStatus = .pending
//        HassRestClient(baseURL: baseURL, authToken: authToken).changeState(entityId: entityId, newState: newState) { [weak self] result in
//            DispatchQueue.main.async {
//                print("[GarageRestManager] REST call completed for entity action: \(entityId).")
//                switch result {
//                case .success(let entity):
//                    print("[GarageRestManager] Success changing state for \(entityId): \(entity)")
//                    self?.lastCallStatus = .success
//                    self?.processState(entity)
//                    self?.error = nil
//                    self?.hasErrorOccurred = false
//                case .failure(let error):
//                    print("[GarageRestManager] Failure changing state for \(entityId): \(error)")
//                    self?.lastCallStatus = .failure
//                    self?.error = error
//                    self?.hasErrorOccurred = true
//                }
//            }
//        }
//    }
    
    func handleScriptAction(entityId: String) {
        print("[GarageRestManager] Handling script action for \(entityId)")
        lastCallStatus = .pending
        HassRestClient(baseURL: baseURL, authToken: authToken).callScript(entityId: entityId) { [weak self] (result: Result<Void, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("[GarageRestManager] Script executed successfully")
                    self?.lastCallStatus = .success
                    self?.error = nil
                    self?.hasErrorOccurred = false
                case .failure(let error):
                    print("[GarageRestManager] Error executing script \(entityId): \(error)")
                    self?.lastCallStatus = .failure
                    self?.error = error
                    self?.hasErrorOccurred = true
                }
            }
        }
    }
    
    func toggleSwitch(entityId: String) {
        print("[GarageRestManager] Toggling switch for \(entityId)")
        lastCallStatus = .pending
        HassRestClient(baseURL: baseURL, authToken: authToken).callService(domain: "switch", service: "toggle", entityId: entityId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("[GarageRestManager] Successfully toggled switch \(entityId)")
                    self?.lastCallStatus = .success
                    self?.error = nil
                    self?.hasErrorOccurred = false
                    // Optionally fetch state if needed to update UI or confirm change
                    self?.stateCheckDelay(delayLength: 3.0)
                    //self?.fetchInitialState()
                case .failure(let error):
                    print("[GarageRestManager] Error toggling switch \(entityId): \(error)")
                    self?.lastCallStatus = .failure
                    self?.error = error
                    self?.hasErrorOccurred = true
                }
            }
        }
    }
    
    func stateCheckDelay(delayLength: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delayLength) {
            self.fetchInitialState()
        }
    }
}
