import Foundation

struct Step: Identifiable, Codable, Equatable {
    var id = UUID()
    var isOn: Bool = false
    var isAccent: Bool = false
    var note: Int = 60
    var velocity: Int = 100
    var length: Float = 0.5      // fraction of step: 0.0625–1.0
    var probability: Float = 1.0 // 0–1
}

struct Track: Identifiable, Codable {
    var id = UUID()
    var name: String = "Track"
    var steps: [Step]
    var stepCount: Int = 16 {
        didSet { resizeSteps() }
    }
    var isMuted: Bool = false
    var isSolo: Bool = false
    var midiChannel: Int = 1   // 1–16; 0 = internal
    var color: String = "#00ff88"

    init() {
        steps = Array(repeating: Step(), count: 16)
    }

    mutating func toggleStep(at index: Int) {
        guard steps.indices.contains(index) else { return }
        steps[index].isOn.toggle()
    }

    mutating func setAccent(at index: Int, _ value: Bool) {
        guard steps.indices.contains(index) else { return }
        steps[index].isAccent = value
    }

    private mutating func resizeSteps() {
        if stepCount > steps.count {
            let extra = Array(repeating: Step(), count: stepCount - steps.count)
            steps.append(contentsOf: extra)
        } else {
            steps = Array(steps.prefix(stepCount))
        }
    }
}

struct Pattern: Identifiable, Codable {
    var id = UUID()
    var name: String = "A1"
    var tracks: [Track]
    var stepCount: Int = 16

    init() {
        tracks = (0..<8).map { i in
            var t = Track()
            t.name = "Track \(i + 1)"
            return t
        }
    }
}
