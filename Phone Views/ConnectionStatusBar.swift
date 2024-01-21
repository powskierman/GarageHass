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
    @EnvironmentObject var garageRestManager: GarageRestManager

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(statusColor)
            Text(message)
                .font(.footnote)
                .foregroundColor(statusColor)
        }
    }

    private var statusImageName: String {
        switch garageRestManager.lastCallStatus {
        case .success:
            return "checkmark.circle"
        case .failure:
            return "xmark.octagon"
        case .pending:
            return "hourglass"
//        default:
//            return "questionmark.circle"
        }
    }

    private var statusColor: Color {
        switch garageRestManager.lastCallStatus {
        case .success:
            return Color.green
        case .failure:
            return Color.red
        case .pending:
            return Color.orange
//        default:
//            return Color.gray
        }
    }
}

struct ConnectionStatusBar_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionStatusBar(message: "API Call Status")
            .environmentObject(GarageRestManager.shared) // Provide a sample object for previews
    }
}
