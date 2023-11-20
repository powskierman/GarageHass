//
//  ConnectionStatusBar.swift
//  GarageNew
//
//  Created by Michel Lapointe on 2022-10-24.
//

import SwiftUI
import HassFramework

struct ConnectionStatusBar: View {
    var message: String
    @Binding var connectionState: ConnectionState
    
    // Computed property to check if the connection state represents a connected state.
    var isConnected: Bool {
        connectionState == .connected
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isConnected ? "wifi" : "wifi.slash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(isConnected ? Color.teal : Color.pink)
            Text(message)
                .font(.footnote)
                .foregroundColor(isConnected ? Color.teal : Color.pink)
        }
    }
}

struct ConnectionStatusBar_Previews: PreviewProvider {
    @State static var sampleConnectionState: ConnectionState = .connected
    
    static var previews: some View {
        ConnectionStatusBar(message: "Connection Status", connectionState: $sampleConnectionState)
    }
}

