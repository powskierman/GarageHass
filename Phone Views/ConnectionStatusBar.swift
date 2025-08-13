import SwiftUI
import HassFramework

struct ConnectionStatusBar: View {
    var message: String
    @EnvironmentObject var garageRestManager: GarageRestManager

    var body: some View {
        HStack(spacing: 10) {
            // Status icon
            Image(systemName: statusImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(statusColor)
            
            // Status message
            Text(message)
                .font(.footnote)
                .foregroundColor(statusColor)
            
            Spacer()
            
            // Refresh button
            Button(action: {
                garageRestManager.fetchInitialState()
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
            }
            .disabled(garageRestManager.lastCallStatus == .pending)
            .opacity(garageRestManager.lastCallStatus == .pending ? 0.5 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var statusImageName: String {
        switch garageRestManager.lastCallStatus {
        case .success:
            return "checkmark.circle"
        case .failure:
            return "xmark.octagon"
        case .pending:
            return "hourglass"
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
        }
    }
}

struct ConnectionStatusBar_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionStatusBar(message: "API Call Status")
            .environmentObject(GarageRestManager.shared)
    }
}
