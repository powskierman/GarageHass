//
//  GarageRestManager.swift
//  GarageHass
//
//  Created by Michel Lapointe on 2024-01-18.
//

import Foundation
import Combine
import HassFramework

//class GarageRestManager: ObservableObject {
//    private var restClient: HassRestClient
//
//    init(restClient: HassRestClient = HassRestClient()) {
//        self.restClient = restClient
//    }

class GarageRestManager: ObservableObject {
    static let shared = GarageRestManager()
    
    @Published var leftDoorClosed: Bool = true
    @Published var rightDoorClosed: Bool = true
    @Published var alarmOff: Bool = true
    @Published var error: Error?
    @Published var hasErrorOccurred: Bool = false

    private var restClient: HassRestClient
    private var cancellables = Set<AnyCancellable>()

    init(restClient: HassRestClient = HassRestClient()) {
        self.restClient = restClient
        // Additional setup if needed
    }

    func fetchInitialState() {
        let doorSensors = ["binary_sensor.left_door_sensor", "binary_sensor.right_door_sensor", "binary_sensor.alarm_sensor"]
        doorSensors.forEach { entityId in
            restClient.fetchState(entityId: entityId) { [weak self] result in
                switch result {
                case .success(let entity):
                    DispatchQueue.main.async {
                        self?.processState(entity)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.error = error
                        self?.hasErrorOccurred = true
                    }
                }
            }
        }
    }

    private func processState(_ entity: HAEntity) {
        switch entity.entityId {
        case "binary_sensor.left_door_sensor":
            leftDoorClosed = entity.state == "off"
        case "binary_sensor.right_door_sensor":
            rightDoorClosed = entity.state == "off"
        case "binary_sensor.alarm_sensor":
            alarmOff = entity.state == "off"
        default:
            break
        }
    }

    func handleEntityAction(entityId: String, newState: String) {
        restClient.changeState(entityId: entityId, newState: newState) { [weak self] result in
            switch result {
            case .success(let entity):
                DispatchQueue.main.async {
                    self?.processState(entity)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.error = error
                    self?.hasErrorOccurred = true
                }
            }
        }
    }
}
