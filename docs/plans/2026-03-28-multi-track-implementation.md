# Multi-Track Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add 4 independent internal synth voices + MIDI-out routing per track, each with its own VCO/VCF/ENV settings, configurable via a per-track bottom sheet.

**Architecture:** Replace SynthEngine's single VCO→VCF→ENV chain with 4 `SynthVoice` instances summed through a `Mixer → OUT`. Each track owns one voice slot (1:1, static) or routes to a MIDI channel. Per-track `TrackVoiceSettings` are applied before each note trigger.

**Tech Stack:** Swift/SwiftUI, AudioKit, SoundpipeAudioKit (`DynamicOscillator`, `MoogLadder`, `AmplitudeEnvelope`, `Mixer`, `Fader`)

---

### Task 1: Data Models

**Files:**
- Modify: `e10dSynth/Sequencer/SequencerModels.swift`
- Create: `e10dSynthTests/SequencerModelTests.swift`

**Context:**
`Track` currently has `midiChannel: Int` (1–16, 0=internal). We replace it with a typed `voiceType` enum plus a `voiceSettings` struct. `VCOWaveform` is already defined in `VCOModule.swift` — import or re-use it directly since it's in the same module.

**Step 1: Write the failing test**

Create `e10dSynthTests/SequencerModelTests.swift`:

```swift
import XCTest
@testable import e10dSynth

final class SequencerModelTests: XCTestCase {

    func testTrackVoiceTypeDefaultIsInternal() {
        let track = Track()
        if case .internalVoice = track.voiceType { } else {
            XCTFail("Expected internalVoice default")
        }
    }

    func testTrackVoiceTypeCodableRoundTrip() throws {
        var track = Track()
        track.voiceType = .midiOut(channel: 7)
        let data = try JSONEncoder().encode(track)
        let decoded = try JSONDecoder().decode(Track.self, from: data)
        if case .midiOut(let ch) = decoded.voiceType {
            XCTAssertEqual(ch, 7)
        } else {
            XCTFail("Expected midiOut after round-trip")
        }
    }

    func testVoiceSettingsDefaults() {
        let s = TrackVoiceSettings()
        XCTAssertEqual(s.waveform, .sawtooth)
        XCTAssertEqual(s.octave, 4)
        XCTAssertEqual(s.cutoff, 1000, accuracy: 0.01)
    }

    func testInternalVoiceCountHelper() {
        var pattern = Pattern()
        // default: all 8 tracks are .internalVoice
        XCTAssertEqual(pattern.internalVoiceCount, 8)
        pattern.tracks[0].voiceType = .midiOut(channel: 1)
        XCTAssertEqual(pattern.internalVoiceCount, 7)
    }

    func testInternalVoiceIndexForTrack() {
        var pattern = Pattern()
        pattern.tracks[1].voiceType = .midiOut(channel: 2)
        // track[0] = internal → index 0
        // track[1] = midi → no index
        // track[2] = internal → index 1
        XCTAssertEqual(pattern.internalVoiceIndex(for: pattern.tracks[0].id), 0)
        XCTAssertNil(pattern.internalVoiceIndex(for: pattern.tracks[1].id))
        XCTAssertEqual(pattern.internalVoiceIndex(for: pattern.tracks[2].id), 1)
    }
}
```

**Step 2: Run test — verify it fails**

```
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|FAILED|PASSED" | head -20
```
Expected: compile error — `TrackVoiceType`, `TrackVoiceSettings`, `internalVoiceCount`, `internalVoiceIndex` not defined yet.

**Step 3: Implement**

Replace the contents of `e10dSynth/Sequencer/SequencerModels.swift`:

```swift
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
```

**Step 4: Run tests — verify they pass**

```
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:e10dSynthTests/SequencerModelTests 2>&1 | grep -E "passed|failed|error:" | head -20
```
Expected: 5 tests pass.

**Step 5: Commit**

```bash
git add e10dSynth/Sequencer/SequencerModels.swift e10dSynthTests/SequencerModelTests.swift
git commit -m "feat: TrackVoiceType + TrackVoiceSettings data models"
```

---

### Task 2: SynthEngine — 4 Voices

**Files:**
- Modify: `e10dSynth/Audio/SynthEngine.swift`

**Context:**
Replace the single `vco`/`vcf`/`env` properties with an array of 4 `SynthVoice` values. Each voice wires `VCO → VCF → ENV`. All 4 ENVs feed into an AudioKit `Mixer`, which feeds `OUT`. The existing `vca` and graph/patch machinery can stay for the optional rack patching UI — we just bypass it for the default 4-voice setup.

`applySettings(_:to:)` must be called before `noteOn` to update the voice's modules. Because `VCFModule.setInput` and `ENVModule.setInput` rebuild the AudioKit node, we cannot call them while the engine is running — so `applySettings` only updates parameter values (cutoff, resonance, ADSR, etc.), not the graph topology.

**Step 1: Write SynthVoice type at the top of SynthEngine.swift**

Add before `@Observable final class SynthEngine`:

```swift
struct SynthVoice {
    let vco: VCOModule
    let vcf: VCFModule
    let env: ENVModule
}
```

**Step 2: Replace single-voice properties and setupDefaultPatch**

New `SynthEngine` body (full replacement):

```swift
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

    // Legacy single-voice refs kept for rack patching UI compatibility
    var vco: VCOModule { voices[0].vco }
    var vcf: VCFModule { voices[0].vcf }
    var env: ENVModule { voices[0].env }
    private(set) var vca: VCAModule = VCAModule()

    private init() {
        // Build 4 voices
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

        // Mix all voices → OUT
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

    /// Apply TrackVoiceSettings to a voice's modules (params only, no graph rewire).
    func applySettings(_ settings: TrackVoiceSettings, to voiceIndex: Int) {
        guard voices.indices.contains(voiceIndex) else { return }
        let v = voices[voiceIndex]
        v.vco.waveform = settings.waveform
        v.vco.octave   = settings.octave
        v.vco.tune     = settings.tune
        v.vcf.cutoff   = settings.cutoff
        v.vcf.resonance = settings.resonance
        v.env.attack   = settings.attack
        v.env.decay    = settings.decay
        v.env.sustain  = settings.sustain
        v.env.release  = settings.release
        // volume applied via amplitude scaling in noteOn
    }

    func noteOn(note: Int, velocity: Int, voiceIndex: Int) {
        guard voices.indices.contains(voiceIndex) else { return }
        let v = voices[voiceIndex]
        let scaledVel = Int(Float(velocity) * voices[voiceIndex].env.sustain)  // unused — use raw vel
        v.vco.noteOn(note, velocity: velocity)
        v.env.trigger()
    }

    func noteOff(note: Int, voiceIndex: Int) {
        guard voices.indices.contains(voiceIndex) else { return }
        voices[voiceIndex].vco.noteOff()
        voices[voiceIndex].env.releaseGate()
    }

    // Legacy noteOn/noteOff (used by MIDI input — routes to voice 0)
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
}
```

**Note:** Remove `rebuildAudioChain()` and `createModule(type:)` — they were used only by the rack patching UI which binds to the graph directly. If rack UI needs them later, they can be re-added. Check `RackView.swift` and `RackViewModel.swift` to verify they don't call these — if they do, keep stub versions that are no-ops.

**Step 3: Check rack UI usages**

```
grep -rn "rebuildAudioChain\|createModule" e10dSynth/
```

If hits found in non-SynthEngine files, keep stubs:
```swift
func rebuildAudioChain() { /* rack patching not supported in 4-voice mode */ }
func createModule(type: ModuleType) -> any SynthModule { VCOModule() }
```

**Step 4: Build — verify no compile errors**

```
xcodebuild build -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `Build succeeded`

**Step 5: Commit**

```bash
git add e10dSynth/Audio/SynthEngine.swift
git commit -m "feat: replace single voice with 4-voice SynthEngine + Mixer"
```

---

### Task 3: Sequencer Routing

**Files:**
- Modify: `e10dSynth/Sequencer/SequencerViewModel.swift`

**Context:**
`handleTick` currently calls both `midiEngine?.sendNoteOn` and `synthEngine?.noteOn` for every track. We now route based on `track.voiceType`: internal tracks apply settings and hit a specific voice, MIDI tracks send to the specified channel only.

`internalVoiceIndex(for:)` is already on `Pattern` (added in Task 1).

**Step 1: Replace handleTick**

Replace the `handleTick` method in `SequencerViewModel.swift`:

```swift
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
```

**Step 2: Build — verify no compile errors**

```
xcodebuild build -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|Build succeeded"
```

**Step 3: Commit**

```bash
git add e10dSynth/Sequencer/SequencerViewModel.swift
git commit -m "feat: route sequencer ticks to voice index or MIDI channel"
```

---

### Task 4: Voice Badge in Track Row

**Files:**
- Modify: `e10dSynth/Views/Sequencer/SequencerView.swift`

**Context:**
Each track row's left header (68pt wide, currently shows name + M/S buttons) needs a tappable badge on the right showing the voice assignment. We'll add it between the M/S buttons and the step grid divider. Tapping opens a `VoiceEditorSheet` (Task 5).

The badge must know the current `Pattern` to compute voice index and check if 4 internal slots are full. Pass the full `SequencerViewModel` (already available as `vm`).

**Step 1: Add sheet state and badge to SequencerView**

Add state var at top of `SequencerView`:
```swift
@State private var editingVoiceTrackIndex: Int? = nil
```

Replace the track row header `VStack` (the 68pt block) in `trackRow(vm:trackIndex:)`:

```swift
VStack(alignment: .leading, spacing: 3) {
    Text(vm.activePattern.tracks[trackIndex].name)
        .font(.synthLabel).foregroundStyle(Color.synthGreen).lineLimit(1)
    HStack(spacing: 4) {
        toggleButton("M", isOn: vm.activePattern.tracks[trackIndex].isMuted,
                     activeColor: .synthAmber) {
            vm.activePattern.tracks[trackIndex].isMuted.toggle()
        }
        toggleButton("S", isOn: vm.activePattern.tracks[trackIndex].isSolo,
                     activeColor: .synthGreen) {
            vm.activePattern.tracks[trackIndex].isSolo.toggle()
        }
        Spacer()
        voiceBadge(vm: vm, trackIndex: trackIndex)
    }
}
.frame(width: 68)
.padding(.horizontal, 6)
```

Add the `voiceBadge` helper:

```swift
@ViewBuilder
private func voiceBadge(vm: SequencerViewModel, trackIndex: Int) -> some View {
    let track = vm.activePattern.tracks[trackIndex]
    let label: String
    let color: Color
    switch track.voiceType {
    case .internalVoice:
        let idx = vm.activePattern.internalVoiceIndex(for: track.id) ?? 0
        label = "I\(idx + 1)"
        color = .synthGreen
    case .midiOut(let ch):
        label = "M\(ch)"
        color = Color(red: 0.2, green: 0.6, blue: 1.0)
    }
    Button {
        editingVoiceTrackIndex = trackIndex
    } label: {
        Text(label)
            .font(.synthLabel)
            .foregroundStyle(Color.synthBg)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(color)
    }
}
```

Add `.sheet` for voice editor after the existing step-edit sheet:

```swift
.sheet(item: Binding(
    get: { editingVoiceTrackIndex.map { IdentifiableInt(value: $0) } },
    set: { editingVoiceTrackIndex = $0?.value }
)) { item in
    if let vm {
        VoiceEditorSheet(
            track: Binding(
                get: { vm.activePattern.tracks[item.value] },
                set: { vm.activePattern.tracks[item.value] = $0 }
            ),
            internalSlotsFull: vm.activePattern.internalVoiceCount >= 4
                && vm.activePattern.tracks[item.value].voiceType != .internalVoice
        )
    }
}
```

Add `IdentifiableInt` helper at the bottom of the file:

```swift
private struct IdentifiableInt: Identifiable {
    let value: Int
    var id: Int { value }
}
```

**Step 2: Build — verify no compile errors**

```
xcodebuild build -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|Build succeeded"
```
Expected: error on `VoiceEditorSheet` not found (Task 5 not done yet). That's fine — comment out the `.sheet` block temporarily to confirm everything else compiles.

**Step 3: Commit (without the sheet binding — placeholder)**

```bash
git add e10dSynth/Views/Sequencer/SequencerView.swift
git commit -m "feat: voice badge in track row header"
```

---

### Task 5: VoiceEditorSheet

**Files:**
- Create: `e10dSynth/Views/Sequencer/VoiceEditorSheet.swift`
- Modify: `e10dSynth/Views/Sequencer/SequencerView.swift` (uncomment sheet binding)

**Context:**
Bottom sheet for editing a track's voice type and settings. Two modes:
- **Internal**: waveform picker, octave stepper, tune knob, cutoff knob, resonance knob, A/D/S/R knobs, volume knob
- **MIDI**: channel picker (1–16)

When switching to Internal and `internalSlotsFull == true`, show an alert instead. The `KnobView` component is already in `e10dSynth/Views/Components/KnobView.swift`.

**Step 1: Create VoiceEditorSheet.swift**

```swift
import SwiftUI

struct VoiceEditorSheet: View {
    @Binding var track: Track
    let internalSlotsFull: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showSlotFullAlert = false

    private var isInternal: Bool {
        if case .internalVoice = track.voiceType { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(track.name.uppercased())
                    .font(.synthMonoLg).foregroundStyle(Color.synthGreen)
                Spacer()
                Button("DONE") { dismiss() }
                    .font(.synthMono).foregroundStyle(Color.synthAmber)
            }
            .padding()

            // Internal / MIDI toggle
            Picker("", selection: Binding(
                get: { isInternal ? 0 : 1 },
                set: { newVal in
                    if newVal == 0 {
                        if internalSlotsFull { showSlotFullAlert = true }
                        else { track.voiceType = .internalVoice }
                    } else {
                        let ch: Int
                        if case .midiOut(let c) = track.voiceType { ch = c } else { ch = 1 }
                        track.voiceType = .midiOut(channel: ch)
                    }
                }
            )) {
                Text("INTERNAL").tag(0)
                Text("MIDI OUT").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 12)

            Divider().background(Color.synthBorder)

            if isInternal {
                internalParams
            } else {
                midiParams
            }
        }
        .background(Color.synthPanel)
        .presentationDetents([.medium, .large])
        .alert("No Voice Slots Available", isPresented: $showSlotFullAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("All 4 internal voice slots are in use. Set another track to MIDI OUT first.")
        }
    }

    @ViewBuilder
    private var internalParams: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Waveform
                VStack(alignment: .leading, spacing: 6) {
                    Text("WAVEFORM").font(.synthLabel).foregroundStyle(Color.synthText)
                    HStack(spacing: 8) {
                        ForEach(VCOWaveform.allCases, id: \.self) { w in
                            Button(w.rawValue.uppercased()) {
                                track.voiceSettings.waveform = w
                            }
                            .font(.synthLabel)
                            .foregroundStyle(track.voiceSettings.waveform == w ? Color.synthBg : Color.synthGreen)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(track.voiceSettings.waveform == w ? Color.synthGreen : Color.clear)
                        }
                    }
                }

                // Octave + Tune
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OCTAVE").font(.synthLabel).foregroundStyle(Color.synthText)
                        Stepper("\(track.voiceSettings.octave)", value: $track.voiceSettings.octave, in: 0...8)
                            .font(.synthMono).foregroundStyle(Color.synthGreen)
                    }
                    KnobView(label: "TUNE", value: $track.voiceSettings.tune, range: -24...24, unit: "st")
                }

                // VCF
                Text("FILTER").font(.synthLabel).foregroundStyle(Color.synthText)
                HStack(spacing: 16) {
                    KnobView(label: "CUTOFF", value: $track.voiceSettings.cutoff, range: 20...20000, unit: "Hz")
                    KnobView(label: "RES",    value: $track.voiceSettings.resonance, range: 0...0.99)
                }

                // ENV
                Text("ENVELOPE").font(.synthLabel).foregroundStyle(Color.synthText)
                HStack(spacing: 12) {
                    KnobView(label: "A", value: $track.voiceSettings.attack,  range: 0...4, unit: "s")
                    KnobView(label: "D", value: $track.voiceSettings.decay,   range: 0...4, unit: "s")
                    KnobView(label: "S", value: $track.voiceSettings.sustain, range: 0...1)
                    KnobView(label: "R", value: $track.voiceSettings.release, range: 0...4, unit: "s")
                }

                // Volume
                KnobView(label: "VOL", value: $track.voiceSettings.volume, range: 0...1)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var midiParams: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MIDI CHANNEL").font(.synthLabel).foregroundStyle(Color.synthText)
                .padding(.horizontal)

            let currentChannel: Int = {
                if case .midiOut(let ch) = track.voiceType { return ch }
                return 1
            }()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                ForEach(1...16, id: \.self) { ch in
                    Button("\(ch)") {
                        track.voiceType = .midiOut(channel: ch)
                    }
                    .font(.synthMono)
                    .foregroundStyle(ch == currentChannel ? Color.synthBg : Color.synthGreen)
                    .frame(maxWidth: .infinity).padding(.vertical, 6)
                    .background(ch == currentChannel ? Color.synthGreen : Color.synthBorder)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 12)
    }
}
```

**Step 2: Uncomment sheet binding in SequencerView.swift**

Remove the temporary comment added in Task 4. The `.sheet(item:)` block for `editingVoiceTrackIndex` should now be active.

**Step 3: Build — verify no compile errors**

```
xcodebuild build -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "error:|Build succeeded"
```
Expected: `Build succeeded`

**Step 4: Run all tests**

```
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "passed|failed|error:" | head -30
```
Expected: all tests pass.

**Step 5: Commit**

```bash
git add e10dSynth/Views/Sequencer/VoiceEditorSheet.swift e10dSynth/Views/Sequencer/SequencerView.swift
git commit -m "feat: VoiceEditorSheet — per-track internal/MIDI voice config"
```
