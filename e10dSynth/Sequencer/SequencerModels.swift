import Foundation

// MARK: - Voice Configuration

enum TrackVoiceType: Codable, Equatable {
    case internalVoice
    case midiOut(channel: Int)
}

struct TrackVoiceSettings: Codable, Equatable {
    var waveform: VCOWaveform = .sawtooth
    /// Absolute octave 0–8 (maps directly to VCOModule.octave)
    var octave: Int = 4
    /// Semitone offset -24...+24 (maps to VCOModule.tune)
    var tune: Float = 0
    var cutoff: Float = 1000
    var resonance: Float = 0.1
    var attack: Float = 0.01
    var decay: Float = 0.1
    var sustain: Float = 0.8
    var release: Float = 0.3
    var volume: Float = 0.8
}

// MARK: - Step

struct Step: Identifiable, Codable, Equatable {
    var id = UUID()
    var isOn: Bool = false
    var isAccent: Bool = false
    var note: Int = 60
    var velocity: Int = 100
    var length: Float = 0.5
    var probability: Float = 1.0
}

// MARK: - Track

struct Track: Identifiable, Codable {
    var id = UUID()
    var name: String = "Track"
    var steps: [Step]
    var stepCount: Int = 16 {
        didSet { resizeSteps() }
    }
    var isMuted: Bool = false
    var isSolo: Bool = false
    var color: String = "#00ff88"
    var voiceType: TrackVoiceType = .internalVoice
    var voiceSettings: TrackVoiceSettings = TrackVoiceSettings()

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
            steps.append(contentsOf: Array(repeating: Step(), count: stepCount - steps.count))
        } else {
            steps = Array(steps.prefix(stepCount))
        }
    }
}

// MARK: - Pattern

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

    /// How many tracks are currently set to .internalVoice
    var internalVoiceCount: Int {
        tracks.filter { if case .internalVoice = $0.voiceType { return true }; return false }.count
    }

    /// 0-based index among internal-voice tracks (nil if track is midiOut)
    func internalVoiceIndex(for trackId: UUID) -> Int? {
        var idx = 0
        for track in tracks {
            if track.id == trackId {
                if case .internalVoice = track.voiceType { return idx }
                return nil
            }
            if case .internalVoice = track.voiceType { idx += 1 }
        }
        return nil
    }
}
