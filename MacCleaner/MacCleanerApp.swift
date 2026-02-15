import SwiftUI

@main
struct MacCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 680, height: 520)
        .windowResizability(.contentMinSize)
    }
}
