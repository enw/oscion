import Foundation
import AudioKit
import SoundpipeAudioKit

final class ENVModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .env
    let name: String = "ENV"

    let inputs: [Jack] = [
        Jack(id: "gateIn", name: "Gate", signalType: .gate, direction: .input),
    ]
    let outputs: [Jack] = [
        Jack(id: "cvOut", name: "CV Out", signalType: .cv, direction: .output),
    ]

    var envelope: AmplitudeEnvelope
    var outputNode: (any Node)? { envelope }

    var attack: Float = 0.01 {
        didSet {
            attack = max(0, attack)
            envelope.attackDuration = attack
        }
    }
    var decay: Float = 0.1 {
        didSet {
            decay = min(10, max(0, decay))
            envelope.decayDuration = decay
        }
    }
    var sustain: Float = 0.8 {
        didSet {
            sustain = min(1.0, max(0, sustain))
            envelope.sustainLevel = sustain
        }
    }
    var release: Float = 0.3 {
        didSet {
            release = max(0, release)
            envelope.releaseDuration = release
        }
    }

    private(set) var isOpen: Bool = false

    init(id: String = UUID().uuidString) {
        self.id = id
        envelope = AmplitudeEnvelope(Mixer())
        envelope.attackDuration = 0.01
        envelope.decayDuration = 0.1
        envelope.sustainLevel = 0.8
        envelope.releaseDuration = 0.3
    }

    /// Rebuild envelope wrapping the given input node. Call before engine.start().
    func setInput(_ node: any Node) {
        let a = envelope.attackDuration
        let d = envelope.decayDuration
        let s = envelope.sustainLevel
        let r = envelope.releaseDuration
        envelope = AmplitudeEnvelope(node)
        envelope.attackDuration = a
        envelope.decayDuration = d
        envelope.sustainLevel = s
        envelope.releaseDuration = r
    }

    func trigger() {
        isOpen = true
        envelope.openGate()
    }

    func releaseGate() {
        isOpen = false
        envelope.closeGate()
    }
}
