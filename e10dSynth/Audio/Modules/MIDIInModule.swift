import Foundation

final class MIDIInModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .midiIn
    let name: String = "MIDI IN"

    let inputs: [Jack] = []
    let outputs: [Jack] = [
        Jack(id: "gateOut",  name: "Gate",  signalType: .gate, direction: .output),
        Jack(id: "cvPitch",  name: "Pitch", signalType: .cv,   direction: .output),
        Jack(id: "cvVel",    name: "Vel",   signalType: .cv,   direction: .output),
    ]

    var channel: Int = 1

    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
