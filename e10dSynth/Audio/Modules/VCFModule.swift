import Foundation

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
        Jack(id: "audioOut", name: "Out", signalType: .audio, direction: .output),
    ]

    var filterType: VCFType = .lowPass

    var cutoff: Float = 1000 {
        didSet { cutoff = min(20000, max(20, cutoff)) }
    }
    var resonance: Float = 0.5 {
        didSet { resonance = min(0.99, max(0, resonance)) }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
