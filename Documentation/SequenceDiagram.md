``` mermaid
sequenceDiagram
    participant Client as Client Code
    participant GSM as GarageSocketManager
    participant WS as HassWebSocket
    participant WC as WCSession (Watch Connectivity)
    participant HA as HAEventData

    rect rgb(224, 224, 224)
    note right of Client: Initialization
    Client->>GSM: Init
    GSM->>WS: HassWebSocket.shared
    GSM->>GSM: setupBindings()
    GSM->>GSM: setupWebSocketEvents()
    end

    rect rgb(224, 255, 224)
    note right of Client: Establishing Connection
    Client->>GSM: establishConnectionIfNeeded(completion)
    GSM->>WS: isConnected()
    WS->>GSM: isConnected Response
    GSM->>WS: connect(callback)
    WS-->>GSM: Connection Callback (success)
    GSM->>WS: subscribeToEvents()
    end

    rect rgb(224, 224, 224)
    note right of GSM: Handling WebSocket State
    WS-->>GSM: $connectionState
    GSM->>GSM: fetchInitialState()
    GSM->>WS: fetchState(callback)
    WS-->>GSM: State Callback (statesArray)
    GSM->>GSM: processStates(statesArray)
    end

    rect rgb(255, 224, 224)
    note right of Client: Handling Entity Action
    Client->>GSM: handleEntityAction(entityId, newState)
    GSM->>WS: isConnected()
    WS->>GSM: isConnected Response
    GSM->>GSM: Determine Command
    GSM->>WS: sendTextMessage(jsonString)
    end

    rect rgb(224, 224, 255)
    note right of HA: Receiving and Processing Event Messages
    HA->>GSM: handleEventMessage(eventDetail)
    GSM->>GSM: processStateChange(entityId, newState)
    GSM->>WC: sendMessage(message)
    end
