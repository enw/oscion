import Foundation
import AudioKit
import SoundpipeAudioKit

enum VCFType: String, CaseIterable, Codable {
    case lowPass, highPass, bandPass
}

final class VCFModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .vcf
    let name: String = "VCF"

    let inputs: [Jack] = [
        Jack(id: "audioIn",  name: "In",     signalType: .audio, direction: .input),
        Jack(id: "cvCutoff", name: "Cutoff", signalType: .cv,    direction: .input),
    ]
    let outputs: [Jack] = [
        Jack(id: "audioOut", name: "Out",    signalType: .audio, direction: .output),
    ]

    private var filter: MoogLadder
    var outputNode: (any Node)? { filter }

    var filterType: VCFType = .lowPass

    var cutoff: Float = 1000 {
        didSet {
            cutoff = min(20000, max(20, cutoff))
            filter.cutoffFrequency = cutoff
        }
    }
    var resonance: Float = 0.5 {
        didSet {
            resonance = min(0.99, max(0, resonance))
            filter.resonance = resonance
        }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
        filter = MoogLadder(Mixer())
        filter.cutoffFrequency = 1000
        filter.resonance = 0.5
    }

    /// Rebuild filter with real input node. Called by SynthEngine before engine.start().
    func setInput(_ node: any Node) {
        filter = MoogLadder(node, cutoffFrequency: cutoff, resonance: resonance)
    }
}
