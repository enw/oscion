import Foundation

final class OUTModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .out
    let name: String = "OUT"

    let inputs: [Jack] = [
        Jack(id: "audioL", name: "L", signalType: .audio, direction: .input),
        Jack(id: "audioR", name: "R", signalType: .audio, direction: .input),
    ]
    let outputs: [Jack] = []

    var level: Float = 0.8 {
        didSet { level = min(1.0, max(0, level)) }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
