import Foundation

final class VCAModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .vca
    let name: String = "VCA"

    let inputs: [Jack] = [
        Jack(id: "audioIn", name: "In",   signalType: .audio, direction: .input),
        Jack(id: "cvGain",  name: "Gain", signalType: .cv,    direction: .input),
    ]
    let outputs: [Jack] = [
        Jack(id: "audioOut", name: "Out", signalType: .audio, direction: .output),
    ]

    var gain: Float = 1.0 {
        didSet { gain = min(2.0, max(0, gain)) }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
