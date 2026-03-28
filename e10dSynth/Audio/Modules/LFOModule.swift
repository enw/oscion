import Foundation
import AudioKit
import SoundpipeAudioKit

final class LFOModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .lfo
    let name: String = "LFO"

    let inputs: [Jack] = []
    let outputs: [Jack] = [
        Jack(id: "cvOut", name: "CV", signalType: .cv, direction: .output),
    ]

    private let oscillator: DynamicOscillator
    var outputNode: (any Node)? { oscillator }

    var rate: Float = 1.0 {
        didSet { oscillator.frequency = min(20, max(0.01, rate)) }
    }
    var depth: Float = 0.5 {
        didSet { oscillator.amplitude = min(1.0, max(0, depth)) }
    }
    var waveform: VCOWaveform = .sine {
        didSet { oscillator.setWaveform(waveform.table) }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
        oscillator = DynamicOscillator(waveform: Table(.sine), frequency: 1.0, amplitude: 0.5)
        oscillator.start()
    }
}
