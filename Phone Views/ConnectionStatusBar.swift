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
    @EnvironmentObject var garageSocketManager: GarageSocketManager

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: garageSocketManager.connectionState == .connected ? "wifi" : "wifi.slash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(garageSocketManager.connectionState == .connected ? Color.teal : Color.pink)
            Text(message)
                .font(.footnote)
                .foregroundColor(garageSocketManager.connectionState == .connected ? Color.teal : Color.pink)
        }
    }
}

struct ConnectionStatusBar_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionStatusBar(message: "Connection Status")
            .environmentObject(GarageSocketManager.shared) // Provide a sample object for previews
    }
}
