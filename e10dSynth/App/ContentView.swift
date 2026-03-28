import SwiftUI

struct ContentView: View {
    var body: some View {
        SynthView()
            .onAppear { SynthEngine.shared.start() }
    }
}
