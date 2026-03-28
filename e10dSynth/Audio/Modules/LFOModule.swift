import Foundation

final class LFOModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .lfo
    let name: String = "LFO"

    let inputs: [Jack] = []
    let outputs: [Jack] = [
        Jack(id: "cvOut", name: "CV", signalType: .cv, direction: .output),
    ]

    var rate: Float = 1.0 {   // Hz, 0.01...20
        didSet { rate = min(20, max(0.01, rate)) }
    }
    var depth: Float = 0.5 {  // 0...1
        didSet { depth = min(1.0, max(0, depth)) }
    }
    var waveform: VCOWaveform = .sine

    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
