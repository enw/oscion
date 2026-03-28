import Foundation
import AudioKit
import AudioKitEX

final class OUTModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .out
    let name: String = "OUT"

    let inputs: [Jack] = [
        Jack(id: "audioL", name: "L", signalType: .audio, direction: .input),
        Jack(id: "audioR", name: "R", signalType: .audio, direction: .input),
    ]
    let outputs: [Jack] = []

    private var fader: Fader
    var outputNode: (any Node)? { fader }

    var level: Float = 0.8 {
        didSet {
            level = min(1.0, max(0, level))
            fader.gain = level
        }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
        fader = Fader(Mixer())
        fader.gain = 0.8
    }

    /// Rebuild fader with real input node. Called by SynthEngine before engine.start().
    func setInput(_ node: any Node) {
        fader = Fader(node)
        fader.gain = level
    }
}
