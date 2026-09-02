import SwiftUI
import SwiftData

@main
struct ReadBuddyApp: App {
    @StateObject private var gaze = GazeTrackingCoordinator()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(gaze)
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [ReadingProgressRecord.self, ReadingSessionRecord.self])
    }
}
