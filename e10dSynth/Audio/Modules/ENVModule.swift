import Foundation

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

    var attack: Float = 0.01 {
        didSet { attack = max(0, attack) }
    }
    var decay: Float = 0.1 {
        didSet { decay = min(10, max(0, decay)) }
    }
    var sustain: Float = 0.8 {
        didSet { sustain = min(1.0, max(0, sustain)) }
    }
    var release: Float = 0.3 {
        didSet { release = max(0, release) }
    }

    private(set) var isOpen: Bool = false

    init(id: String = UUID().uuidString) {
        self.id = id
    }

    func trigger() {
        isOpen = true
    }

    func releaseGate() {
        isOpen = false
    }
}
