import Foundation
import AudioKit
import SoundpipeAudioKit

enum VCOWaveform: String, CaseIterable, Codable, Equatable {
    case sine, sawtooth, square, triangle

    var table: Table {
        switch self {
        case .sine:     return Table(.sine)
        case .sawtooth: return Table(.sawtooth)
        case .square:   return Table(.square)
        case .triangle: return Table(.triangle)
        }
    }
}

final class VCOModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .vco
    let name: String = "VCO"

    let inputs: [Jack] = [
        Jack(id: "cvPitch",  name: "V/Oct", signalType: .cv,    direction: .input),
        Jack(id: "cvFM",     name: "FM",    signalType: .cv,    direction: .input),
        Jack(id: "gateIn",   name: "Gate",  signalType: .gate,  direction: .input),
    ]
    let outputs: [Jack] = [
        Jack(id: "audioOut", name: "Out",   signalType: .audio, direction: .output),
    ]

    private let oscillator: DynamicOscillator
    var outputNode: (any Node)? { oscillator }

    var waveform: VCOWaveform = .sawtooth {
        didSet { oscillator.setWaveform(waveform.table) }
    }
    /// Semitone offset -24...+24
    var tune: Float = 0 {
        didSet { tune = min(24, max(-24, tune)); updateFrequency() }
    }
    /// Base octave 0...8
    var octave: Int = 4 {
        didSet { octave = min(8, max(0, octave)); updateFrequency() }
    }
    private(set) var midiNote: Int = 69
    private(set) var amplitude: Float = 0.5

    init(id: String = UUID().uuidString) {
        self.id = id
        oscillator = DynamicOscillator(waveform: Table(.sawtooth))
        oscillator.amplitude = 0.5
        updateFrequency()
        oscillator.start()
    }

    func noteOn(_ note: Int, velocity: Int) {
        midiNote = min(127, max(0, note))
        amplitude = Float(velocity) / 127.0 * 0.8
        oscillator.amplitude = amplitude
        updateFrequency()
    }

    func noteOff() {
        amplitude = 0
        oscillator.amplitude = 0
    }

    var frequency: Float {
        let semitones = Float(midiNote - 69) + tune
        return 440.0 * pow(2.0, semitones / 12.0)
    }

    private func updateFrequency() {
        oscillator.frequency = frequency
    }
}
