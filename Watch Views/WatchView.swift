import SwiftUI
import WatchConnectivity

struct WatchView: View {
    @ObservedObject var watchViewModel: WatchViewModel

    var body: some View {
        TabView {
            // Left Door Tab
            WatchEntityView(viewModel: watchViewModel, entityType: .door(.left))
                .tabItem {
                    Label("Left Door", systemImage: "garage")
                }

            // Right Door Tab
            WatchEntityView(viewModel: watchViewModel, entityType: .door(.right))
                .tabItem {
                    Label("Right Door", systemImage: "garage")
                }

            // Alarm Tab
            WatchEntityView(viewModel: watchViewModel, entityType: .alarm)
                .tabItem {
                    Label("Alarm", systemImage: "alarm")
                }
        }
    }
}
