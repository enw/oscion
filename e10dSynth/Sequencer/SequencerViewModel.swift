import Foundation

@Observable
final class SequencerViewModel {

    var patterns: [Pattern] = {
        let rows = ["A", "B", "C", "D"]
        return (0..<16).map { i in
            var p = Pattern()
            p.name = "\(rows[i / 4])\(i % 4 + 1)"
            return p
        }
    }()

    var activePatternIndex: Int = 0
    var activePattern: Pattern {
        get { patterns[activePatternIndex] }
        set { patterns[activePatternIndex] = newValue }
    }

    var currentStep: Int = 0
    var isPlaying: Bool = false

    let clock = SequencerClock()

    // Injected after init
    weak var midiEngine: MIDIEngine?
    weak var synthEngine: SynthEngine?

    init() {
        clock.onTick = { [weak self] step in
            self?.handleTick(step)
        }
    }

    func play() {
        isPlaying = true
        clock.start()
        midiEngine?.sendStart()
    }

    func stop() {
        isPlaying = false
        clock.stop()
        currentStep = 0
        midiEngine?.sendStop()
    }

    func toggleStep(trackIndex: Int, stepIndex: Int) {
        guard activePattern.tracks.indices.contains(trackIndex) else { return }
        activePattern.tracks[trackIndex].toggleStep(at: stepIndex)
    }

    private func handleTick(_ step: Int) {
        let localStep = step % activePattern.stepCount
        DispatchQueue.main.async { [weak self] in self?.currentStep = localStep }

        for track in activePattern.tracks {
            guard !track.isMuted else { continue }
            let s = track.steps[localStep % track.steps.count]
            guard s.isOn else { continue }
            guard s.probability >= 1.0 || Float.random(in: 0...1) <= s.probability else { continue }
            let vel = s.isAccent ? min(127, s.velocity + 20) : s.velocity

            switch track.voiceType {
            case .internalVoice:
                guard let vi = activePattern.internalVoiceIndex(for: track.id),
                      vi < 4 else { continue }
                synthEngine?.applySettings(track.voiceSettings, to: vi)
                synthEngine?.noteOn(note: s.note, velocity: vel, voiceIndex: vi)
                let noteOffDelay = clock.stepInterval * Double(s.length)
                DispatchQueue.main.asyncAfter(deadline: .now() + noteOffDelay) { [weak self] in
                    self?.synthEngine?.noteOff(note: s.note, voiceIndex: vi)
                }

            case .midiOut(let channel):
                midiEngine?.sendNoteOn(note: s.note, velocity: vel, channel: channel)
                let noteOffDelay = clock.stepInterval * Double(s.length)
                DispatchQueue.main.asyncAfter(deadline: .now() + noteOffDelay) { [weak self] in
                    self?.midiEngine?.sendNoteOff(note: s.note, channel: channel)
                }
            }
        }

        for _ in 0..<6 { midiEngine?.sendClock() }
    }
}
