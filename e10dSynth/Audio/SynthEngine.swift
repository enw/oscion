import Foundation
import AudioKit
import SoundpipeAudioKit

struct SynthVoice {
    let vco: VCOModule
    let vcf: VCFModule
    let env: ENVModule
}

@Observable
final class SynthEngine {
    static let shared = SynthEngine()

    let audioEngine = AudioEngine()
    let graph = ModularGraph()
    let midiEngineInstance = MIDIEngine()

    private(set) var isRunning = false

    // 4 independent voices
    private(set) var voices: [SynthVoice]
    private let voiceMixer: Mixer
    private(set) var out: OUTModule

    // Legacy single-voice refs for rack patching UI compatibility
    var vco: VCOModule { voices[0].vco }
    var vcf: VCFModule { voices[0].vcf }
    var env: ENVModule { voices[0].env }
    private(set) var vca: VCAModule = VCAModule()

    private init() {
        var built: [SynthVoice] = []
        for _ in 0..<4 {
            let vco = VCOModule()
            let vcf = VCFModule()
            let env = ENVModule()
            vcf.setInput(vco.outputNode!)
            env.setInput(vcf.outputNode!)
            built.append(SynthVoice(vco: vco, vcf: vcf, env: env))
        }
        voices = built

        let envNodes = built.map { $0.env.outputNode! }
        voiceMixer = Mixer(envNodes)
        out = OUTModule()
        out.setInput(voiceMixer)

        wireMIDICallbacks()
    }

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        do {
            audioEngine.output = out.outputNode
            try audioEngine.start()
            isRunning = true
            midiEngineInstance.start()
        } catch {
            print("[SynthEngine] start error: \(error)")
        }
    }

    func stop() {
        audioEngine.stop()
        midiEngineInstance.stop()
        isRunning = false
    }

    // MARK: - Per-Voice Control

    func applySettings(_ settings: TrackVoiceSettings, to voiceIndex: Int) {
        guard voices.indices.contains(voiceIndex) else { return }
        let v = voices[voiceIndex]
        v.vco.waveform  = settings.waveform
        v.vco.octave    = settings.octave
        v.vco.tune      = settings.tune
        v.vcf.cutoff    = settings.cutoff
        v.vcf.resonance = settings.resonance
        v.env.attack    = settings.attack
        v.env.decay     = settings.decay
        v.env.sustain   = settings.sustain
        v.env.release   = settings.release
    }

    func noteOn(note: Int, velocity: Int, voiceIndex: Int) {
        guard voices.indices.contains(voiceIndex) else { return }
        let v = voices[voiceIndex]
        v.vco.noteOn(note, velocity: velocity)
        v.env.trigger()
    }

    func noteOff(note: Int, voiceIndex: Int) {
        guard voices.indices.contains(voiceIndex) else { return }
        voices[voiceIndex].vco.noteOff()
        voices[voiceIndex].env.releaseGate()
    }

    // Legacy overloads — MIDI input routes to voice 0
    func noteOn(note: Int, velocity: Int) {
        noteOn(note: note, velocity: velocity, voiceIndex: 0)
    }

    func noteOff(note: Int) {
        noteOff(note: note, voiceIndex: 0)
    }

    // MARK: - MIDI

    private func wireMIDICallbacks() {
        midiEngineInstance.onNoteOn = { [weak self] note, velocity in
            self?.noteOn(note: note, velocity: velocity)
        }
        midiEngineInstance.onNoteOff = { [weak self] note in
            self?.noteOff(note: note)
        }
    }

    // MARK: - Rack UI Stubs

    func rebuildAudioChain() {}

    func createModule(type: ModuleType) -> any SynthModule {
        switch type {
        case .vco:     return VCOModule()
        case .vcf:     return VCFModule()
        case .vca:     return VCAModule()
        case .env:     return ENVModule()
        case .lfo:     return LFOModule()
        case .midiIn:  return MIDIInModule()
        case .midiOut: return MIDIOutModule()
        case .out:     return OUTModule()
        case .seq:     fatalError("Sequencer module not implemented as SynthModule")
        }
    }
}
