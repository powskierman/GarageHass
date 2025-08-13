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
        let sensors = ["binary_sensor.left_door_sensor", "binary_sensor.right_door_sensor", "binary_sensor.reversed_sensor"]
        
        // Keep track of completed calls
        var completedCalls = 0
        let totalCalls = sensors.count
        var hasError = false
        
        // Call all sensors at the same time (concurrent calls) with retry logic
        sensors.forEach { entityId in
            fetchStateWithRetry(entityId: entityId) { [weak self] result in
                DispatchQueue.main.async {
                    completedCalls += 1
                    print("[GarageRestManager] REST call completed for entityId: \(entityId). (\(completedCalls)/\(totalCalls))")
                    
                    switch result {
                    case .success(let entity):
                        print("[GarageRestManager] Success fetching state for \(entityId): \(entity)")
                        self?.processState(entity)
                        
                        // Only set success if this is the last call and no errors occurred
                        if completedCalls == totalCalls && !hasError {
                            self?.lastCallStatus = .success
                            self?.error = nil
                            self?.hasErrorOccurred = false
                        }
                        
                    case .failure(let error):
                        print("[GarageRestManager] Failure fetching state for \(entityId): \(error)")
                        hasError = true
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
        case "binary_sensor.reversed_sensor":
            alarmOff = entity.state == "off"
        default:
            print("[GarageRestManager] State changed or unprocessed entity: \(entity.entityId)")
            break
        }
    }

    private func fetchStateWithRetry(entityId: String, attempt: Int = 1, completion: @escaping (Result<HAEntity, Error>) -> Void) {
        let maxRetries = 3
        let baseDelay = 1.0 // seconds
        
        HassRestClient(baseURL: baseURL, authToken: authToken).fetchState(entityId: entityId) { result in
            switch result {
            case .success(let entity):
                completion(.success(entity))
                
            case .failure(let error):
                if attempt < maxRetries {
                    let delay = baseDelay * Double(attempt) // 1s, 2s, 3s delays
                    print("[GarageRestManager] Retry \(attempt)/\(maxRetries) for \(entityId) in \(delay)s")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.fetchStateWithRetry(entityId: entityId, attempt: attempt + 1, completion: completion)
                    }
                } else {
                    print("[GarageRestManager] Failed after \(maxRetries) attempts for \(entityId)")
                    completion(.failure(error))
                }
            }
        }
    }
    
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
                    // Add a 1-second delay before fetching the state
  //                  DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.fetchInitialState()
 //                   }
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
