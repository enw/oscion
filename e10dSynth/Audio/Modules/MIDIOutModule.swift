import Foundation

final class MIDIOutModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .midiOut
    let name: String = "MIDI OUT"

    let inputs: [Jack] = [
        Jack(id: "gateIn",  name: "Gate",  signalType: .gate, direction: .input),
        Jack(id: "cvPitch", name: "Pitch", signalType: .cv,   direction: .input),
        Jack(id: "cvVel",   name: "Vel",   signalType: .cv,   direction: .input),
    ]
    let outputs: [Jack] = []

    var channel: Int = 1

    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
