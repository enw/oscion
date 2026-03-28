import Foundation
import AudioKit
import AudioKitEX

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

    private var fader: Fader
    var outputNode: (any Node)? { fader }

    var gain: Float = 1.0 {
        didSet {
            gain = min(2.0, max(0, gain))
            fader.gain = gain
        }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
        fader = Fader(Mixer())
        fader.gain = 1.0
    }

    /// Rebuild fader with real input node. Called by SynthEngine before engine.start().
    func setInput(_ node: any Node) {
        fader = Fader(node)
        fader.gain = gain
    }
}
