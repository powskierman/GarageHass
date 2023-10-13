//
//  ConnectionStatusBar.swift
//  GarageNew
//
//  Created by Michel Lapointe on 2022-10-24.
//

import SwiftUI

struct ConnectionStatusBar: View {
    var message: String
    var isConnected: Bool

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
    static var previews: some View {
        ConnectionStatusBar(message: "Connection Status", isConnected: true)
    }
}
