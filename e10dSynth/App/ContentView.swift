import SwiftUI

struct ContentView: View {
    @Environment(SynthEngine.self) var engine

    var body: some View {
        TabView {
            RackView()
                .tabItem { Label("Rack", systemImage: "hexagon") }

            SequencerView()
                .tabItem { Label("Seq", systemImage: "grid") }

            MIDIRoutingView()
                .tabItem { Label("MIDI", systemImage: "arrow.left.arrow.right") }
        }
        .tint(Color.synthGreen)
        .onAppear { engine.start() }
        .toolbarBackground(Color.synthPanel, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
