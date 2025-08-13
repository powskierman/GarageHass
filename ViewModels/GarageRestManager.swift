import Foundation
import Combine
import HassFramework

// Extension to make Result more convenient
extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

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
    private let baseURL: URL?
    private let authToken: String?
    
    // Constants
    private struct Constants {
        static let maxRetries = 3
        static let baseDelay = 1.0
        static let entityIds = [
            "binary_sensor.left_door_sensor",
            "binary_sensor.right_door_sensor", 
            "binary_sensor.reversed_sensor"
        ]
    }
    
    // Thread-safe counters
    private let completionQueue = DispatchQueue(label: "com.garagehass.completion", attributes: .concurrent)

    private init() {
        // Load baseURL and authToken from Secrets.plist
        if let secretsPath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let secrets = NSDictionary(contentsOfFile: secretsPath) as? [String: Any],
           let serverURLString = secrets["RESTURL"] as? String,
           let authToken = secrets["authToken"] as? String,
           let baseURL = URL(string: serverURLString) {
            
            self.baseURL = baseURL
            self.authToken = authToken
            print("[GarageRestManager] Initialized with REST client.")
        } else {
            self.baseURL = nil
            self.authToken = nil
            self.initializationFailed = true
            print("[GarageRestManager] Failed to initialize: Invalid or missing configuration in Secrets.plist.")
        }
    }
    
    func fetchInitialState() {
        guard let baseURL = baseURL, let authToken = authToken else {
            DispatchQueue.main.async {
                self.lastCallStatus = .failure
                self.error = NSError(domain: "GarageRestManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Configuration not available"])
                self.hasErrorOccurred = true
            }
            return
        }
        
        print("[GarageRestManager] Fetching initial state.")
        lastCallStatus = .pending
        let sensors = Constants.entityIds
        
        // Thread-safe counters using actor-like pattern
        let callTracker = CallTracker(totalCalls: sensors.count)
        
        // Call all sensors at the same time (concurrent calls) with retry logic
        sensors.forEach { entityId in
            fetchStateWithRetry(entityId: entityId, baseURL: baseURL, authToken: authToken) { [weak self] result in
                let (isComplete, shouldSetSuccess) = callTracker.recordCompletion(success: result.isSuccess)
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let entity):
                        print("[GarageRestManager] Success fetching state for \(entityId): \(entity)")
                        self?.processState(entity)
                        
                        if isComplete && shouldSetSuccess {
                            self?.handleCompletionSuccess()
                        }
                        
                    case .failure(let error):
                        print("[GarageRestManager] Failure fetching state for \(entityId): \(error)")
                        self?.handleCompletionFailure(error)
                    }
                }
            }
        }
    }

    // Thread-safe call tracker
    private class CallTracker {
        private let queue = DispatchQueue(label: "com.garagehass.calltracker")
        private var completedCalls = 0
        private let totalCalls: Int
        private var hasError = false
        
        init(totalCalls: Int) {
            self.totalCalls = totalCalls
        }
        
        func recordCompletion(success: Bool) -> (isComplete: Bool, shouldSetSuccess: Bool) {
            return queue.sync {
                completedCalls += 1
                if !success {
                    hasError = true
                }
                let isComplete = completedCalls == totalCalls
                let shouldSetSuccess = isComplete && !hasError
                return (isComplete, shouldSetSuccess)
            }
        }
    }
    
    private func handleCompletionSuccess() {
        lastCallStatus = .success
        error = nil
        hasErrorOccurred = false
    }
    
    private func handleCompletionFailure(_ error: Error) {
        lastCallStatus = .failure
        self.error = error
        hasErrorOccurred = true
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

    private func fetchStateWithRetry(entityId: String, baseURL: URL, authToken: String, attempt: Int = 1, completion: @escaping (Result<HAEntity, Error>) -> Void) {
        HassRestClient(baseURL: baseURL, authToken: authToken).fetchState(entityId: entityId) { [weak self] result in
            switch result {
            case .success(let entity):
                completion(.success(entity))
                
            case .failure(let error):
                if attempt < Constants.maxRetries {
                    let delay = Constants.baseDelay * Double(attempt) // 1s, 2s, 3s delays
                    print("[GarageRestManager] Retry \(attempt)/\(Constants.maxRetries) for \(entityId) in \(delay)s")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self?.fetchStateWithRetry(entityId: entityId, baseURL: baseURL, authToken: authToken, attempt: attempt + 1, completion: completion)
                    }
                } else {
                    print("[GarageRestManager] Failed after \(Constants.maxRetries) attempts for \(entityId)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func handleScriptAction(entityId: String) {
        guard let baseURL = baseURL, let authToken = authToken else {
            handleCompletionFailure(NSError(domain: "GarageRestManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Configuration not available"]))
            return
        }
        
        print("[GarageRestManager] Handling script action for \(entityId)")
        lastCallStatus = .pending
        HassRestClient(baseURL: baseURL, authToken: authToken).callScript(entityId: entityId) { [weak self] (result: Result<Void, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("[GarageRestManager] Script executed successfully")
                    self?.handleCompletionSuccess()
                case .failure(let error):
                    print("[GarageRestManager] Error executing script \(entityId): \(error)")
                    self?.handleCompletionFailure(error)
                }
            }
        }
    }
    
    func toggleSwitch(entityId: String) {
        guard let baseURL = baseURL, let authToken = authToken else {
            handleCompletionFailure(NSError(domain: "GarageRestManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Configuration not available"]))
            return
        }
        
        print("[GarageRestManager] Toggling switch for \(entityId)")
        lastCallStatus = .pending
        HassRestClient(baseURL: baseURL, authToken: authToken).callService(domain: "switch", service: "toggle", entityId: entityId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("[GarageRestManager] Successfully toggled switch \(entityId)")
                    self?.handleCompletionSuccess()
                    self?.fetchInitialState()
                case .failure(let error):
                    print("[GarageRestManager] Error toggling switch \(entityId): \(error)")
                    self?.handleCompletionFailure(error)
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
