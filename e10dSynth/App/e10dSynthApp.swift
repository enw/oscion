import SwiftUI

@main
struct e10dSynthApp: App {
    @State private var engine = SynthEngine.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(engine)
                .preferredColorScheme(.dark)
        }
    }
}
