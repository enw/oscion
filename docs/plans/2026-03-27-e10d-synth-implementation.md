# e10d Synth — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** SwiftUI iOS modular analog synth + step sequencer with AudioKit DSP, CoreMIDI virtual I/O, free-form patch cables, and retro CRT aesthetic.

**Architecture:** AudioKit 5 handles DSP. `ModularGraph` maps logical patch connections to AudioKit node connections. `SynthEngine` (`@Observable` singleton) owns all nodes. CoreMIDI provides virtual in/out ports. SwiftUI renders the rack canvas (zoomable, scrollable) and step sequencer grid.

**Tech Stack:** Swift 6, SwiftUI, AudioKit 5.6, AudioKitEX, SoundpipeAudioKit, CoreMIDI, AVAudioEngine, iOS 17+

---

## Setup

Install xcodegen before starting:
```bash
brew install xcodegen
```

Run tests throughout with:
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)"
```

---

### Task 1: Xcode Project via xcodegen

**Files:**
- Create: `project.yml`
- Create: `e10dSynth/App/e10dSynthApp.swift`
- Create: `e10dSynth/App/ContentView.swift`
- Create: `e10dSynthTests/e10dSynthTests.swift`

**Step 1: Write project.yml**

```yaml
name: e10dSynth
options:
  bundleIdPrefix: com.e10d
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"
  swift: "6.0"

packages:
  AudioKit:
    url: https://github.com/AudioKit/AudioKit
    exactVersion: 5.6.4
  SoundpipeAudioKit:
    url: https://github.com/AudioKit/SoundpipeAudioKit
    exactVersion: 4.0.3
  AudioKitEX:
    url: https://github.com/AudioKit/AudioKitEX
    exactVersion: 5.6.2

targets:
  e10dSynth:
    type: application
    platform: iOS
    sources: [e10dSynth]
    settings:
      base:
        INFOPLIST_FILE: e10dSynth/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.e10d.synth
        TARGETED_DEVICE_FAMILY: "1,2"
    dependencies:
      - package: AudioKit
        product: AudioKit
      - package: SoundpipeAudioKit
        product: SoundpipeAudioKit
      - package: AudioKitEX
        product: AudioKitEX
    info:
      path: e10dSynth/Info.plist
      properties:
        UILaunchStoryboardName: ""
        UISupportedInterfaceOrientations~ipad:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
        UIBackgroundModes:
          - audio
        NSMicrophoneUsageDescription: "Used for audio output routing"

  e10dSynthTests:
    type: bundle.unit-test
    platform: iOS
    sources: [e10dSynthTests]
    dependencies:
      - target: e10dSynth
```

**Step 2: Create app entry point**

`e10dSynth/App/e10dSynthApp.swift`:
```swift
import SwiftUI
import AudioKit

@main
struct e10dSynthApp: App {
    @State private var engine = SynthEngine.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(engine)
                .preferredColorScheme(.dark)
        }
    }
}
```

**Step 3: Create placeholder ContentView**

`e10dSynth/App/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("e10d")
            .font(.system(.largeTitle, design: .monospaced))
            .foregroundStyle(Color.synthGreen)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.synthBg)
    }
}
```

**Step 4: Create test placeholder**

`e10dSynthTests/e10dSynthTests.swift`:
```swift
import XCTest
@testable import e10dSynth

final class e10dSynthTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }
}
```

**Step 5: Generate project**
```bash
cd /Users/enw/Documents/Projects/e10d-analog-synth
xcodegen generate
```

**Step 6: Open and resolve packages in Xcode**
- Open `e10dSynth.xcodeproj`
- File → Packages → Resolve Package Versions
- Build once to confirm (Cmd+B)

**Step 7: Commit**
```bash
git add .
git commit -m "bootstrap: xcode project with audiokit"
```

---

### Task 2: Design Tokens

**Files:**
- Create: `e10dSynth/Style/Colors.swift`
- Create: `e10dSynth/Style/Fonts.swift`

**Step 1: Write colors**

`e10dSynth/Style/Colors.swift`:
```swift
import SwiftUI

extension Color {
    static let synthBg       = Color(hex: "#0a0a0a")
    static let synthGrid     = Color(hex: "#1a2a1a")
    static let synthGreen    = Color(hex: "#00ff88")
    static let synthAmber    = Color(hex: "#ffaa00")
    static let synthRed      = Color(hex: "#ff4444")
    static let synthDimGreen = Color(hex: "#004422")
    static let synthDimAmber = Color(hex: "#332200")
    static let synthPanel    = Color(hex: "#0f1a0f")
    static let synthBorder   = Color(hex: "#1e3a1e")
    static let synthText     = Color(hex: "#88cc88")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// Signal type colors
extension Color {
    static func signalColor(_ type: SignalType) -> Color {
        switch type {
        case .audio: return .synthGreen
        case .cv:    return .synthAmber
        case .gate:  return .synthRed
        }
    }
}
```

**Step 2: Write fonts**

`e10dSynth/Style/Fonts.swift`:
```swift
import SwiftUI

extension Font {
    static let synthMono     = Font.system(.body, design: .monospaced)
    static let synthMonoSm   = Font.system(.caption, design: .monospaced)
    static let synthMonoLg   = Font.system(.title3, design: .monospaced)
    static let synthMonoXl   = Font.system(.title, design: .monospaced)
    static let synthLabel    = Font.system(.caption2, design: .monospaced).uppercaseSmallCaps()
}
```

**Step 3: Commit**
```bash
git add e10dSynth/Style/
git commit -m "style: design tokens — crt color palette + mono fonts"
```

---

### Task 3: Core Models

**Files:**
- Create: `e10dSynth/Models/SignalType.swift`
- Create: `e10dSynth/Models/Jack.swift`
- Create: `e10dSynth/Models/Patch.swift`
- Create: `e10dSynth/Models/ModuleProtocol.swift`
- Create: `e10dSynthTests/ModelTests.swift`

**Step 1: Write failing tests**

`e10dSynthTests/ModelTests.swift`:
```swift
import XCTest
@testable import e10dSynth

final class ModelTests: XCTestCase {

    func testSignalTypeColorDistinct() {
        XCTAssertNotEqual(SignalType.audio.rawValue, SignalType.cv.rawValue)
        XCTAssertNotEqual(SignalType.cv.rawValue, SignalType.gate.rawValue)
    }

    func testJackDirectionIncompatibleWithSelf() {
        let out = Jack(id: "o1", name: "Out", signalType: .audio, direction: .output)
        let out2 = Jack(id: "o2", name: "Out2", signalType: .audio, direction: .output)
        XCTAssertFalse(out.canConnect(to: out2))
    }

    func testJackCompatibleAudioToAudio() {
        let out = Jack(id: "o1", name: "Out", signalType: .audio, direction: .output)
        let inp = Jack(id: "i1", name: "In", signalType: .audio, direction: .input)
        XCTAssertTrue(out.canConnect(to: inp))
    }

    func testJackIncompatibleAudioToCV() {
        let out = Jack(id: "o1", name: "Out", signalType: .audio, direction: .output)
        let inp = Jack(id: "i1", name: "In", signalType: .cv, direction: .input)
        XCTAssertFalse(out.canConnect(to: inp))
    }

    func testPatchCodable() throws {
        let patch = Patch(
            fromModuleId: "m1", fromJackId: "j1",
            toModuleId: "m2", toJackId: "j2"
        )
        let data = try JSONEncoder().encode(patch)
        let decoded = try JSONDecoder().decode(Patch.self, from: data)
        XCTAssertEqual(patch.id, decoded.id)
    }
}
```

**Step 2: Run tests to verify they fail**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)" | head -10
```
Expected: compile errors for missing types.

**Step 3: Implement models**

`e10dSynth/Models/SignalType.swift`:
```swift
import Foundation

enum SignalType: String, Codable, CaseIterable {
    case audio
    case cv
    case gate
}
```

`e10dSynth/Models/Jack.swift`:
```swift
import Foundation

enum JackDirection: String, Codable {
    case input, output
}

struct Jack: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let signalType: SignalType
    let direction: JackDirection

    func canConnect(to other: Jack) -> Bool {
        guard direction == .output, other.direction == .input else { return false }
        return signalType == other.signalType
    }
}
```

`e10dSynth/Models/Patch.swift`:
```swift
import Foundation

struct Patch: Identifiable, Codable, Equatable {
    let id: UUID
    let fromModuleId: String
    let fromJackId: String
    let toModuleId: String
    let toJackId: String

    init(fromModuleId: String, fromJackId: String, toModuleId: String, toJackId: String) {
        self.id = UUID()
        self.fromModuleId = fromModuleId
        self.fromJackId = fromJackId
        self.toModuleId = toModuleId
        self.toJackId = toJackId
    }
}
```

`e10dSynth/Models/ModuleProtocol.swift`:
```swift
import Foundation
import AudioKit

enum ModuleType: String, Codable, CaseIterable {
    case vco, vcf, vca, env, lfo, seq, midiIn, midiOut, out
}

protocol SynthModule: AnyObject, Identifiable {
    var id: String { get }
    var moduleType: ModuleType { get }
    var name: String { get }
    var inputs: [Jack] { get }
    var outputs: [Jack] { get }
    var outputNode: Node? { get }
}
```

**Step 4: Run tests**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: all PASS.

**Step 5: Commit**
```bash
git add e10dSynth/Models/ e10dSynthTests/ModelTests.swift
git commit -m "models: signaltype, jack, patch, module protocol"
```

---

### Task 4: ModularGraph

**Files:**
- Create: `e10dSynth/Audio/ModularGraph.swift`
- Create: `e10dSynthTests/ModularGraphTests.swift`

**Step 1: Write failing tests**

`e10dSynthTests/ModularGraphTests.swift`:
```swift
import XCTest
@testable import e10dSynth

final class ModularGraphTests: XCTestCase {

    var graph: ModularGraph!

    override func setUp() {
        graph = ModularGraph()
    }

    func testAddModule() {
        let m = MockModule(id: "m1")
        graph.add(m)
        XCTAssertEqual(graph.modules.count, 1)
    }

    func testAddPatchValid() {
        let m1 = MockModule(id: "m1")
        let m2 = MockModule(id: "m2")
        graph.add(m1); graph.add(m2)
        let result = graph.connect(
            fromModule: "m1", fromJack: "audioOut",
            toModule: "m2", toJack: "audioIn"
        )
        XCTAssertTrue(result)
        XCTAssertEqual(graph.patches.count, 1)
    }

    func testAddPatchInvalidMissingModule() {
        let result = graph.connect(
            fromModule: "missing", fromJack: "audioOut",
            toModule: "m2", toJack: "audioIn"
        )
        XCTAssertFalse(result)
    }

    func testRemovePatch() {
        let m1 = MockModule(id: "m1")
        let m2 = MockModule(id: "m2")
        graph.add(m1); graph.add(m2)
        _ = graph.connect(fromModule: "m1", fromJack: "audioOut", toModule: "m2", toJack: "audioIn")
        let patchId = graph.patches.first!.id
        graph.disconnect(patchId)
        XCTAssertTrue(graph.patches.isEmpty)
    }
}
```

Also add to test file:
```swift
// MARK: - Test helpers
class MockModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .vco
    let name: String = "Mock"
    let inputs: [Jack] = [Jack(id: "audioIn", name: "In", signalType: .audio, direction: .input)]
    let outputs: [Jack] = [Jack(id: "audioOut", name: "Out", signalType: .audio, direction: .output)]
    var outputNode: (any Node)? = nil
    init(id: String) { self.id = id }
}
```

**Step 2: Implement ModularGraph**

`e10dSynth/Audio/ModularGraph.swift`:
```swift
import Foundation
import AudioKit

@Observable
final class ModularGraph {
    private(set) var modules: [String: any SynthModule] = [:]
    private(set) var patches: [Patch] = []

    func add(_ module: some SynthModule) {
        modules[module.id] = module
    }

    func remove(_ moduleId: String) {
        modules.removeValue(forKey: moduleId)
        patches.removeAll { $0.fromModuleId == moduleId || $0.toModuleId == moduleId }
    }

    @discardableResult
    func connect(fromModule: String, fromJack: String, toModule: String, toJack: String) -> Bool {
        guard
            let src = modules[fromModule],
            let dst = modules[toModule],
            let srcJack = src.outputs.first(where: { $0.id == fromJack }),
            let dstJack = dst.inputs.first(where: { $0.id == toJack }),
            srcJack.canConnect(to: dstJack)
        else { return false }

        // Prevent duplicate patch
        let exists = patches.contains {
            $0.fromModuleId == fromModule && $0.fromJackId == fromJack &&
            $0.toModuleId == toModule && $0.toJackId == toJack
        }
        guard !exists else { return true }

        let patch = Patch(fromModuleId: fromModule, fromJackId: fromJack,
                          toModuleId: toModule, toJackId: toJack)
        patches.append(patch)
        return true
    }

    func disconnect(_ patchId: UUID) {
        patches.removeAll { $0.id == patchId }
    }

    /// Serialize entire graph for preset saving
    func toPreset() throws -> Data {
        let positions = modulePositions
        let preset = GraphPreset(patches: patches, modulePositions: positions)
        return try JSONEncoder().encode(preset)
    }

    // Module positions stored here for layout persistence
    var modulePositions: [String: CGPoint] = [:]
}

struct GraphPreset: Codable {
    let patches: [Patch]
    let modulePositions: [String: CGPoint]
}

extension CGPoint: Codable {
    public init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        self.init(x: try c.decode(CGFloat.self), y: try c.decode(CGFloat.self))
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        try c.encode(x); try c.encode(y)
    }
}
```

**Step 3: Run tests**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: all PASS.

**Step 4: Commit**
```bash
git add e10dSynth/Audio/ModularGraph.swift e10dSynthTests/ModularGraphTests.swift
git commit -m "graph: modular graph with patch connect/disconnect"
```

---

### Task 5: SynthEngine Skeleton

**Files:**
- Create: `e10dSynth/Audio/SynthEngine.swift`

**Step 1: Implement SynthEngine**

`e10dSynth/Audio/SynthEngine.swift`:
```swift
import Foundation
import AudioKit
import SoundpipeAudioKit

@Observable
final class SynthEngine {
    static let shared = SynthEngine()

    let engine = AudioEngine()
    let graph = ModularGraph()

    private(set) var isRunning = false

    private init() {
        setupDefaultPatch()
    }

    func start() {
        do {
            try engine.start()
            isRunning = true
        } catch {
            print("[SynthEngine] start error: \(error)")
        }
    }

    func stop() {
        engine.stop()
        isRunning = false
    }

    private func setupDefaultPatch() {
        // Default: VCO → VCF → VCA → OUT
        let vco = VCOModule()
        let vcf = VCFModule()
        let vca = VCAModule()
        let out = OUTModule()

        graph.add(vco)
        graph.add(vcf)
        graph.add(vca)
        graph.add(out)

        // Connect nodes in AudioKit engine
        vcf.setInput(vco.outputNode!)
        vca.setInput(vcf.outputNode!)
        engine.output = vca.outputNode

        graph.connect(fromModule: vco.id, fromJack: "audioOut",
                      toModule: vcf.id, toJack: "audioIn")
        graph.connect(fromModule: vcf.id, fromJack: "audioOut",
                      toModule: vca.id, toJack: "audioIn")
        graph.connect(fromModule: vca.id, fromJack: "audioOut",
                      toModule: out.id, toJack: "audioIn")
    }
}
```

Note: `VCOModule`, `VCFModule`, `VCAModule`, `OUTModule` are stubs — implemented in Tasks 6–10.

**Step 2: Manual test — app compiles**
Build in Xcode (Cmd+B). Expected: success with stub warnings only.

**Step 3: Commit**
```bash
git add e10dSynth/Audio/SynthEngine.swift
git commit -m "engine: synth engine skeleton with default vco→vcf→vca chain"
```

---

### Task 6: VCO Module

**Files:**
- Create: `e10dSynth/Audio/Modules/VCOModule.swift`
- Create: `e10dSynthTests/VCOModuleTests.swift`

**Step 1: Write failing test**

`e10dSynthTests/VCOModuleTests.swift`:
```swift
import XCTest
import AudioKit
@testable import e10dSynth

final class VCOModuleTests: XCTestCase {

    func testVCOHasCorrectJacks() {
        let vco = VCOModule()
        XCTAssertTrue(vco.outputs.contains { $0.id == "audioOut" && $0.signalType == .audio })
        XCTAssertTrue(vco.inputs.contains { $0.id == "cvPitch" && $0.signalType == .cv })
        XCTAssertTrue(vco.inputs.contains { $0.id == "gateIn" && $0.signalType == .gate })
    }

    func testVCOWaveformChange() {
        let vco = VCOModule()
        vco.waveform = .sawtooth
        XCTAssertEqual(vco.waveform, .sawtooth)
    }

    func testVCOTuneRange() {
        let vco = VCOModule()
        vco.tune = 12.0  // +1 octave semitones
        XCTAssertEqual(vco.tune, 12.0)
    }
}
```

**Step 2: Implement VCOModule**

`e10dSynth/Audio/Modules/VCOModule.swift`:
```swift
import Foundation
import AudioKit
import SoundpipeAudioKit

enum VCOWaveform: String, CaseIterable, Codable {
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

    private let oscillator: Oscillator

    var outputNode: (any Node)? { oscillator }

    // Parameters
    @Observable var waveform: VCOWaveform = .sawtooth {
        didSet { oscillator.setWaveform(waveform.table) }
    }
    /// Semitone offset -24...+24
    var tune: Float = 0 {
        didSet { updateFrequency() }
    }
    /// Base octave 0...8
    var octave: Int = 4 {
        didSet { updateFrequency() }
    }
    /// MIDI note 0...127 (set by SEQ or MIDI IN)
    var midiNote: Int = 69 {
        didSet { updateFrequency() }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
        oscillator = Oscillator(waveform: VCOWaveform.sawtooth.table)
        oscillator.amplitude = 0.5
        updateFrequency()
        oscillator.start()
    }

    func noteOn(_ note: Int, velocity: Int) {
        midiNote = note
        oscillator.amplitude = Float(velocity) / 127.0 * 0.8
    }

    func noteOff() {
        oscillator.amplitude = 0
    }

    private func updateFrequency() {
        let semitones = Float(midiNote - 69) + tune
        let hz = 440.0 * pow(2.0, semitones / 12.0)
        oscillator.frequency = hz
    }
}
```

**Step 3: Run tests**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: PASS.

**Step 4: Manual test**
Call `SynthEngine.shared.start()` from a button. Tap → hear a sawtooth tone.

**Step 5: Commit**
```bash
git add e10dSynth/Audio/Modules/VCOModule.swift e10dSynthTests/VCOModuleTests.swift
git commit -m "module: vco with waveform, tune, octave, midi note"
```

---

### Task 7: VCF Module

**Files:**
- Create: `e10dSynth/Audio/Modules/VCFModule.swift`
- Create: `e10dSynthTests/VCFModuleTests.swift`

**Step 1: Write failing test**

`e10dSynthTests/VCFModuleTests.swift`:
```swift
import XCTest
@testable import e10dSynth

final class VCFModuleTests: XCTestCase {

    func testVCFHasCorrectJacks() {
        let vcf = VCFModule()
        XCTAssertTrue(vcf.inputs.contains { $0.id == "audioIn" && $0.signalType == .audio })
        XCTAssertTrue(vcf.inputs.contains { $0.id == "cvCutoff" && $0.signalType == .cv })
        XCTAssertTrue(vcf.outputs.contains { $0.id == "audioOut" })
    }

    func testVCFCutoffClamped() {
        let vcf = VCFModule()
        vcf.cutoff = 30000  // above max
        XCTAssertLessThanOrEqual(vcf.cutoff, 20000)
        vcf.cutoff = -100   // below min
        XCTAssertGreaterThanOrEqual(vcf.cutoff, 20)
    }
}
```

**Step 2: Implement VCFModule**

`e10dSynth/Audio/Modules/VCFModule.swift`:
```swift
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

    private let filter: MoogLadder
    var outputNode: (any Node)? { filter }

    var filterType: VCFType = .lowPass  // MoogLadder is LP; type switches node in future

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
        // Initialized with a silent source; real input connected via setInput
        filter = MoogLadder(Silence())
        filter.cutoffFrequency = 1000
        filter.resonance = 0.5
    }

    func setInput(_ node: any Node) {
        // Reconnect MoogLadder with real input
        // AudioKit doesn't support dynamic input swap; rebuild node
        // This is called during graph construction, before engine starts
        _ = MoogLadder(node, cutoffFrequency: cutoff, resonance: resonance)
        // Note: in production, SynthEngine rebuilds the chain when patches change
    }
}
```

> **Note on VCF dynamic reconnection:** AudioKit nodes can't swap inputs after engine start. `SynthEngine.rebuildChain()` (Task 5 extension) stops the engine, rewires nodes, restarts. This is acceptable for patch cable changes (not real-time).

**Step 3: Run tests**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: PASS.

**Step 4: Commit**
```bash
git add e10dSynth/Audio/Modules/VCFModule.swift e10dSynthTests/VCFModuleTests.swift
git commit -m "module: vcf (moog ladder filter) with cutoff + resonance"
```

---

### Task 8: VCA + ENV Modules

**Files:**
- Create: `e10dSynth/Audio/Modules/VCAModule.swift`
- Create: `e10dSynth/Audio/Modules/ENVModule.swift`
- Create: `e10dSynthTests/VCAENVTests.swift`

**Step 1: Write failing tests**

`e10dSynthTests/VCAENVTests.swift`:
```swift
import XCTest
@testable import e10dSynth

final class VCAENVTests: XCTestCase {

    func testVCAJacks() {
        let vca = VCAModule()
        XCTAssertTrue(vca.inputs.contains { $0.id == "audioIn" })
        XCTAssertTrue(vca.inputs.contains { $0.id == "cvGain" && $0.signalType == .cv })
        XCTAssertTrue(vca.outputs.contains { $0.id == "audioOut" })
    }

    func testENVJacks() {
        let env = ENVModule()
        XCTAssertTrue(env.inputs.contains { $0.id == "gateIn" && $0.signalType == .gate })
        XCTAssertTrue(env.outputs.contains { $0.id == "cvOut" && $0.signalType == .cv })
    }

    func testENVParameterBounds() {
        let env = ENVModule()
        env.attack = -1; XCTAssertGreaterThanOrEqual(env.attack, 0)
        env.decay = 100; XCTAssertLessThanOrEqual(env.decay, 10)
        env.sustain = 2.0; XCTAssertLessThanOrEqual(env.sustain, 1.0)
    }
}
```

**Step 2: Implement VCAModule**

`e10dSynth/Audio/Modules/VCAModule.swift`:
```swift
import Foundation
import AudioKit

final class VCAModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .vca
    let name: String = "VCA"

    let inputs: [Jack] = [
        Jack(id: "audioIn", name: "In",   signalType: .audio, direction: .input),
        Jack(id: "cvGain",  name: "Gain", signalType: .cv,    direction: .input),
    ]
    let outputs: [Jack] = [
        Jack(id: "audioOut", name: "Out", signalType: .audio, direction: .output),
    ]

    private let fader: Fader
    var outputNode: (any Node)? { fader }

    var gain: Float = 1.0 {
        didSet { fader.gain = min(2.0, max(0, gain)) }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
        fader = Fader(Silence())
        fader.gain = 1.0
    }

    func setInput(_ node: any Node) {
        // Rebuilt by SynthEngine on patch change
    }
}
```

**Step 3: Implement ENVModule**

`e10dSynth/Audio/Modules/ENVModule.swift`:
```swift
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

    // ENV drives amplitude of a connected VCA via AmplitudeEnvelope
    let envelope: AmplitudeEnvelope
    var outputNode: (any Node)? { envelope }

    var attack: Float = 0.01 {
        didSet {
            attack = max(0, attack)
            envelope.attackDuration = Double(attack)
        }
    }
    var decay: Float = 0.1 {
        didSet {
            decay = min(10, max(0, decay))
            envelope.decayDuration = Double(decay)
        }
    }
    var sustain: Float = 0.8 {
        didSet {
            sustain = min(1.0, max(0, sustain))
            envelope.sustainLevel = Double(sustain)
        }
    }
    var release: Float = 0.3 {
        didSet {
            release = max(0, release)
            envelope.releaseDuration = Double(release)
        }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
        envelope = AmplitudeEnvelope(Silence())
        envelope.attackDuration = 0.01
        envelope.decayDuration = 0.1
        envelope.sustainLevel = 0.8
        envelope.releaseDuration = 0.3
    }

    func trigger() {
        envelope.openGate()
    }

    func release_() {
        envelope.closeGate()
    }
}
```

**Step 4: Run tests**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: PASS.

**Step 5: Commit**
```bash
git add e10dSynth/Audio/Modules/ e10dSynthTests/VCAENVTests.swift
git commit -m "modules: vca (fader) + env (adsr envelope)"
```

---

### Task 9: LFO + OUT Modules

**Files:**
- Create: `e10dSynth/Audio/Modules/LFOModule.swift`
- Create: `e10dSynth/Audio/Modules/OUTModule.swift`

**Step 1: Implement LFOModule**

`e10dSynth/Audio/Modules/LFOModule.swift`:
```swift
import Foundation
import AudioKit
import SoundpipeAudioKit

final class LFOModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .lfo
    let name: String = "LFO"

    let inputs: [Jack] = []
    let outputs: [Jack] = [
        Jack(id: "cvOut", name: "CV", signalType: .cv, direction: .output),
    ]

    private let oscillator: Oscillator
    var outputNode: (any Node)? { oscillator }

    var rate: Float = 1.0 {   // Hz
        didSet { oscillator.frequency = min(20, max(0.01, rate)) }
    }
    var depth: Float = 0.5 {  // 0...1
        didSet { oscillator.amplitude = min(1.0, max(0, depth)) }
    }
    var waveform: VCOWaveform = .sine {
        didSet { oscillator.setWaveform(waveform.table) }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
        oscillator = Oscillator(waveform: Table(.sine), frequency: 1.0, amplitude: 0.5)
        oscillator.start()
    }
}
```

**Step 2: Implement OUTModule**

`e10dSynth/Audio/Modules/OUTModule.swift`:
```swift
import Foundation
import AudioKit

final class OUTModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .out
    let name: String = "OUT"

    let inputs: [Jack] = [
        Jack(id: "audioL", name: "L", signalType: .audio, direction: .input),
        Jack(id: "audioR", name: "R", signalType: .audio, direction: .input),
    ]
    let outputs: [Jack] = []

    private let fader: Fader
    var outputNode: (any Node)? { fader }

    var level: Float = 0.8 {
        didSet { fader.gain = min(1.0, max(0, level)) }
    }

    init(id: String = UUID().uuidString) {
        self.id = id
        fader = Fader(Silence())
        fader.gain = 0.8
    }

    func setInput(_ node: any Node) {
        // Rebuilt by SynthEngine on patch change
    }
}
```

**Step 3: Manual test**
Build succeeds. Tap play → hear sawtooth through the default chain.

**Step 4: Commit**
```bash
git add e10dSynth/Audio/Modules/LFOModule.swift e10dSynth/Audio/Modules/OUTModule.swift
git commit -m "modules: lfo + out"
```

---

### Task 10: MIDI Engine

**Files:**
- Create: `e10dSynth/MIDI/MIDIEngine.swift`
- Create: `e10dSynth/Audio/Modules/MIDIInModule.swift`
- Create: `e10dSynth/Audio/Modules/MIDIOutModule.swift`
- Create: `e10dSynthTests/MIDIEngineTests.swift`

**Step 1: Write failing tests**

`e10dSynthTests/MIDIEngineTests.swift`:
```swift
import XCTest
@testable import e10dSynth

final class MIDIEngineTests: XCTestCase {

    func testMIDIEngineInitializes() {
        let midi = MIDIEngine()
        XCTAssertNotNil(midi)
    }

    func testNoteToFrequency() {
        // A4 = MIDI 69 = 440Hz
        XCTAssertEqual(MIDIEngine.noteToFrequency(69), 440.0, accuracy: 0.01)
        // A3 = MIDI 57 = 220Hz
        XCTAssertEqual(MIDIEngine.noteToFrequency(57), 220.0, accuracy: 0.01)
    }

    func testMIDIChannelRange() {
        let midi = MIDIEngine()
        midi.receiveChannel = 17  // out of range
        XCTAssertLessThanOrEqual(midi.receiveChannel, 16)
        XCTAssertGreaterThanOrEqual(midi.receiveChannel, 1)
    }
}
```

**Step 2: Implement MIDIEngine**

`e10dSynth/MIDI/MIDIEngine.swift`:
```swift
import Foundation
import CoreMIDI
import AudioKit

@Observable
final class MIDIEngine {
    var receiveChannel: Int = 1 {
        didSet { receiveChannel = min(16, max(1, receiveChannel)) }
    }
    var sendChannel: Int = 1

    var onNoteOn:  ((Int, Int) -> Void)?   // note, velocity
    var onNoteOff: ((Int) -> Void)?        // note
    var onCC:      ((Int, Int) -> Void)?   // cc#, value

    private let midi = MIDI()

    init() {
        midi.openInput()
        midi.openOutput()
        midi.addListener(self)
    }

    static func noteToFrequency(_ note: Int) -> Float {
        return 440.0 * pow(2.0, Float(note - 69) / 12.0)
    }

    func sendNoteOn(note: Int, velocity: Int, channel: Int? = nil) {
        let ch = UInt8(channel ?? sendChannel)
        midi.sendNoteOnMessage(noteNumber: MIDINoteNumber(note),
                               velocity: MIDIVelocity(velocity),
                               channel: ch)
    }

    func sendNoteOff(note: Int, channel: Int? = nil) {
        let ch = UInt8(channel ?? sendChannel)
        midi.sendNoteOffMessage(noteNumber: MIDINoteNumber(note),
                                velocity: 0,
                                channel: ch)
    }

    func sendCC(_ cc: Int, value: Int, channel: Int? = nil) {
        let ch = UInt8(channel ?? sendChannel)
        midi.sendControllerMessage(MIDIByte(cc), value: MIDIByte(value), channel: ch)
    }

    func sendClock() {
        midi.sendMessage([0xF8])
    }

    func sendStart() { midi.sendMessage([0xFA]) }
    func sendStop()  { midi.sendMessage([0xFC]) }
}

extension MIDIEngine: MIDIListener {
    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        guard channel + 1 == receiveChannel || receiveChannel == 0 else { return }
        onNoteOn?(Int(noteNumber), Int(velocity))
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        guard channel + 1 == receiveChannel || receiveChannel == 0 else { return }
        onNoteOff?(Int(noteNumber))
    }

    func receivedMIDIController(_ controller: MIDIByte, value: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        onCC?(Int(controller), Int(value))
    }

    func receivedMIDIClock(timeStamp: MIDITimeStamp?) {}
    func receivedMIDISetupChange() {}
    func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {}
    func receivedMIDINotification(notification: MIDINotification) {}
    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIAftertouch(_ pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIAftertouch(noteNumber: MIDINoteNumber, pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIProgramChange(_ program: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDISystemCommand(_ data: [MIDIByte], portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
}
```

**Step 3: Stub MIDI modules**

`e10dSynth/Audio/Modules/MIDIInModule.swift`:
```swift
import Foundation
import AudioKit

final class MIDIInModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .midiIn
    let name: String = "MIDI IN"
    let inputs: [Jack] = []
    let outputs: [Jack] = [
        Jack(id: "gateOut",  name: "Gate",  signalType: .gate, direction: .output),
        Jack(id: "cvPitch",  name: "Pitch", signalType: .cv,   direction: .output),
        Jack(id: "cvVel",    name: "Vel",   signalType: .cv,   direction: .output),
    ]
    var outputNode: (any Node)? = nil
    var channel: Int = 1

    init(id: String = UUID().uuidString) { self.id = id }
}
```

`e10dSynth/Audio/Modules/MIDIOutModule.swift`:
```swift
import Foundation
import AudioKit

final class MIDIOutModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .midiOut
    let name: String = "MIDI OUT"
    let inputs: [Jack] = [
        Jack(id: "gateIn",  name: "Gate",  signalType: .gate, direction: .input),
        Jack(id: "cvPitch", name: "Pitch", signalType: .cv,   direction: .input),
        Jack(id: "cvVel",   name: "Vel",   signalType: .cv,   direction: .input),
    ]
    let outputs: [Jack] = []
    var outputNode: (any Node)? = nil
    var channel: Int = 1

    init(id: String = UUID().uuidString) { self.id = id }
}
```

**Step 4: Run tests**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: PASS.

**Step 5: Commit**
```bash
git add e10dSynth/MIDI/ e10dSynth/Audio/Modules/MIDI*.swift e10dSynthTests/MIDIEngineTests.swift
git commit -m "midi: engine with coreMIDI virtual ports, note/cc in+out"
```

---

### Task 11: Sequencer Models

**Files:**
- Create: `e10dSynth/Sequencer/SequencerModels.swift`
- Create: `e10dSynthTests/SequencerModelTests.swift`

**Step 1: Write failing tests**

`e10dSynthTests/SequencerModelTests.swift`:
```swift
import XCTest
@testable import e10dSynth

final class SequencerModelTests: XCTestCase {

    func testStepDefaultsOff() {
        let step = Step()
        XCTAssertFalse(step.isOn)
    }

    func testTrackDefaultStepCount() {
        let track = Track()
        XCTAssertEqual(track.steps.count, 16)
    }

    func testTrackToggleStep() {
        var track = Track()
        track.toggleStep(at: 0)
        XCTAssertTrue(track.steps[0].isOn)
        track.toggleStep(at: 0)
        XCTAssertFalse(track.steps[0].isOn)
    }

    func testPatternHasEightTracks() {
        let pattern = Pattern()
        XCTAssertEqual(pattern.tracks.count, 8)
    }

    func testStepCodable() throws {
        var step = Step()
        step.isOn = true; step.note = 60; step.velocity = 100
        let data = try JSONEncoder().encode(step)
        let decoded = try JSONDecoder().decode(Step.self, from: data)
        XCTAssertEqual(decoded.note, 60)
        XCTAssertEqual(decoded.velocity, 100)
    }
}
```

**Step 2: Implement models**

`e10dSynth/Sequencer/SequencerModels.swift`:
```swift
import Foundation

struct Step: Identifiable, Codable, Equatable {
    var id = UUID()
    var isOn: Bool = false
    var isAccent: Bool = false
    var note: Int = 60          // MIDI note
    var velocity: Int = 100     // 0–127
    var length: Float = 0.5     // fraction of step: 0.0625 (1/16) to 1.0 (full bar)
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
    var midiChannel: Int = 1    // 1–16, or 0 = internal
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
            steps.append(contentsOf: Array(repeating: Step(), count: stepCount - steps.count))
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
        tracks = Array(repeating: Track(), count: 8)
        for i in 0..<tracks.count {
            tracks[i].name = "Track \(i + 1)"
        }
    }
}
```

**Step 3: Run tests**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: PASS.

**Step 4: Commit**
```bash
git add e10dSynth/Sequencer/SequencerModels.swift e10dSynthTests/SequencerModelTests.swift
git commit -m "sequencer: step/track/pattern models with codable"
```

---

### Task 12: SequencerClock + SequencerViewModel

**Files:**
- Create: `e10dSynth/Sequencer/SequencerClock.swift`
- Create: `e10dSynth/Sequencer/SequencerViewModel.swift`
- Create: `e10dSynthTests/SequencerClockTests.swift`

**Step 1: Write failing tests**

`e10dSynthTests/SequencerClockTests.swift`:
```swift
import XCTest
@testable import e10dSynth

final class SequencerClockTests: XCTestCase {

    func testClockBPMRange() {
        let clock = SequencerClock()
        clock.bpm = 300; XCTAssertLessThanOrEqual(clock.bpm, 250)
        clock.bpm = 10;  XCTAssertGreaterThanOrEqual(clock.bpm, 20)
    }

    func testClockStepInterval() {
        let clock = SequencerClock()
        clock.bpm = 120
        // 120 BPM = 0.5s/beat, 16th note = 0.5/4 = 0.125s
        XCTAssertEqual(clock.stepInterval, 0.125, accuracy: 0.001)
    }

    func testClockSwingRange() {
        let clock = SequencerClock()
        clock.swing = 150; XCTAssertLessThanOrEqual(clock.swing, 100)
        clock.swing = -10; XCTAssertGreaterThanOrEqual(clock.swing, 0)
    }
}
```

**Step 2: Implement SequencerClock**

`e10dSynth/Sequencer/SequencerClock.swift`:
```swift
import Foundation
import AudioKit
import AVFoundation

final class SequencerClock {
    var bpm: Double = 120 {
        didSet { bpm = min(250, max(20, bpm)) }
    }
    var swing: Double = 0 {  // 0–100
        didSet { swing = min(100, max(0, swing)) }
    }

    var stepInterval: TimeInterval { 60.0 / bpm / 4.0 }  // 16th note

    var onTick: ((Int) -> Void)?   // fires with current step index
    var onBar: (() -> Void)?

    private var timer: Timer?
    private var currentStep: Int = 0
    private(set) var isRunning: Bool = false
    private let totalSteps: Int = 32

    func start() {
        guard !isRunning else { return }
        isRunning = true
        currentStep = 0
        scheduleTick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        currentStep = 0
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func scheduleTick() {
        let interval = stepInterval(for: currentStep)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.onTick?(self.currentStep)
            if self.currentStep % 16 == 0 { self.onBar?() }
            self.currentStep = (self.currentStep + 1) % self.totalSteps
            if self.isRunning { self.scheduleTick() }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stepInterval(for step: Int) -> TimeInterval {
        let base = 60.0 / bpm / 4.0
        // Swing: even steps slightly longer, odd steps shorter
        guard swing > 0 else { return base }
        let factor = swing / 100.0 * 0.2  // max ±20% swing
        return step % 2 == 0 ? base * (1 + factor) : base * (1 - factor)
    }
}
```

**Step 3: Implement SequencerViewModel**

`e10dSynth/Sequencer/SequencerViewModel.swift`:
```swift
import Foundation
import AudioKit

@Observable
final class SequencerViewModel {
    // Patterns
    var patterns: [Pattern] = Array(repeating: Pattern(), count: 16)
    var activePatternIndex: Int = 0
    var activePattern: Pattern {
        get { patterns[activePatternIndex] }
        set { patterns[activePatternIndex] = newValue }
    }

    // Playback state
    var currentStep: Int = 0
    var isPlaying: Bool = false
    var selectedTrackIndex: Int = 0

    // Pattern chain
    var patternChain: [Int] = []
    private var chainPosition: Int = 0

    let clock = SequencerClock()

    // Dependencies injected
    var midiEngine: MIDIEngine?
    var synthEngine: SynthEngine?

    init() {
        setupPatternNames()
        clock.onTick = { [weak self] step in
            self?.handleTick(step)
        }
    }

    func play() {
        isPlaying = true
        clock.start()
        synthEngine?.midiEngine.sendStart()
    }

    func stop() {
        isPlaying = false
        clock.stop()
        currentStep = 0
        synthEngine?.midiEngine.sendStop()
    }

    func toggleStep(trackIndex: Int, stepIndex: Int) {
        activePattern.tracks[trackIndex].toggleStep(at: stepIndex)
    }

    func setPatternName(_ index: Int, name: String) {
        patterns[index].name = name
    }

    private func handleTick(_ step: Int) {
        let localStep = step % activePattern.stepCount
        DispatchQueue.main.async {
            self.currentStep = localStep
        }
        // Fire each active track's step
        for track in activePattern.tracks {
            guard !track.isMuted else { continue }
            let s = track.steps[localStep % track.steps.count]
            guard s.isOn else { continue }
            // Probability gate
            if s.probability < 1.0, Float.random(in: 0...1) > s.probability { continue }
            let vel = s.isAccent ? min(127, s.velocity + 20) : s.velocity
            midiEngine?.sendNoteOn(note: s.note, velocity: vel, channel: track.midiChannel)
            synthEngine?.noteOn(note: s.note, velocity: vel)
        }
        // Send MIDI clock (24 ppqn → 6 ticks per 16th)
        for _ in 0..<6 { midiEngine?.sendClock() }
    }

    private func setupPatternNames() {
        let rows = ["A", "B", "C", "D"]
        for i in 0..<16 {
            patterns[i].name = "\(rows[i / 4])\(i % 4 + 1)"
        }
    }
}
```

**Step 4: Run tests**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: PASS.

**Step 5: Commit**
```bash
git add e10dSynth/Sequencer/ e10dSynthTests/SequencerClockTests.swift
git commit -m "sequencer: clock (bpm/swing) + viewmodel with pattern chain"
```

---

### Task 13: RackViewModel

**Files:**
- Create: `e10dSynth/ViewModels/RackViewModel.swift`

**Step 1: Implement RackViewModel**

`e10dSynth/ViewModels/RackViewModel.swift`:
```swift
import Foundation
import SwiftUI

@Observable
final class RackViewModel {
    // Module layout
    var moduleOrder: [String] = []     // module IDs in display order
    var modulePositions: [String: CGPoint] = [:]

    // Patching interaction state
    var draggingFromJack: JackRef? = nil
    var draggingPoint: CGPoint = .zero
    var hoveredJack: JackRef? = nil

    // Jack screen positions (populated by module card views via preference keys)
    var jackPositions: [String: CGPoint] = [:]  // key: "\(moduleId).\(jackId)"

    let graph: ModularGraph
    let engine: SynthEngine

    init(engine: SynthEngine) {
        self.engine = engine
        self.graph = engine.graph
        setupDefaultPositions()
    }

    func jackKey(_ moduleId: String, _ jackId: String) -> String {
        "\(moduleId).\(jackId)"
    }

    func registerJackPosition(moduleId: String, jackId: String, position: CGPoint) {
        jackPositions[jackKey(moduleId, jackId)] = position
    }

    func startDrag(from ref: JackRef, at point: CGPoint) {
        draggingFromJack = ref
        draggingPoint = point
    }

    func updateDrag(to point: CGPoint) {
        draggingPoint = point
    }

    func endDrag(at point: CGPoint) {
        defer {
            draggingFromJack = nil
            hoveredJack = nil
        }
        guard let src = draggingFromJack, let dst = hoveredJack else { return }
        _ = graph.connect(
            fromModule: src.moduleId, fromJack: src.jackId,
            toModule: dst.moduleId, toJack: dst.jackId
        )
        engine.rebuildAudioChain()
    }

    func removePatch(_ id: UUID) {
        graph.disconnect(id)
        engine.rebuildAudioChain()
    }

    func moveModule(_ moduleId: String, to position: CGPoint) {
        modulePositions[moduleId] = position
        graph.modulePositions[moduleId] = position
    }

    func addModule(_ type: ModuleType) {
        let module = engine.createModule(type: type)
        let x = CGFloat.random(in: 100...600)
        let y = CGFloat.random(in: 100...800)
        modulePositions[module.id] = CGPoint(x: x, y: y)
        moduleOrder.append(module.id)
    }

    private func setupDefaultPositions() {
        var x: CGFloat = 40
        for id in graph.modules.keys.sorted() {
            modulePositions[id] = CGPoint(x: x, y: 200)
            moduleOrder.append(id)
            x += 220
        }
    }
}

struct JackRef: Equatable {
    let moduleId: String
    let jackId: String
    let signalType: SignalType
    let direction: JackDirection
}
```

**Step 2: Add `rebuildAudioChain` + `createModule` to SynthEngine**

Append to `e10dSynth/Audio/SynthEngine.swift`:
```swift
extension SynthEngine {
    func rebuildAudioChain() {
        // Stop engine, rewire nodes per graph patches, restart
        engine.stop()
        // Walk patches and reconnect AudioKit nodes
        // (simplified: full rebuild from graph topology)
        engine.output = resolveOutputNode()
        try? engine.start()
    }

    func createModule(type: ModuleType) -> any SynthModule {
        switch type {
        case .vco:     let m = VCOModule();    graph.add(m); return m
        case .vcf:     let m = VCFModule();    graph.add(m); return m
        case .vca:     let m = VCAModule();    graph.add(m); return m
        case .env:     let m = ENVModule();    graph.add(m); return m
        case .lfo:     let m = LFOModule();    graph.add(m); return m
        case .seq:     let m = VCOModule();    graph.add(m); return m // placeholder
        case .midiIn:  let m = MIDIInModule(); graph.add(m); return m
        case .midiOut: let m = MIDIOutModule();graph.add(m); return m
        case .out:     let m = OUTModule();    graph.add(m); return m
        }
    }

    func noteOn(note: Int, velocity: Int) {
        for (_, module) in graph.modules {
            if let vco = module as? VCOModule {
                vco.noteOn(note, velocity: velocity)
            }
            if let env = module as? ENVModule {
                env.trigger()
            }
        }
    }

    func noteOff(note: Int) {
        for (_, module) in graph.modules {
            if let vco = module as? VCOModule { vco.noteOff() }
            if let env = module as? ENVModule { env.release_() }
        }
    }

    private func resolveOutputNode() -> (any Node)? {
        // Find OUT module and walk backwards through patches
        guard let outModule = graph.modules.values.first(where: { $0.moduleType == .out }),
              let outPatch = graph.patches.first(where: { $0.toModuleId == outModule.id }),
              let srcModule = graph.modules[outPatch.fromModuleId]
        else { return nil }
        return srcModule.outputNode
    }

    var midiEngine: MIDIEngine { MIDIEngine() }  // replace with stored instance in full impl
}
```

**Step 3: Manual test — compile, no errors**
```bash
xcodebuild build -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep error:
```
Expected: no errors.

**Step 4: Commit**
```bash
git add e10dSynth/ViewModels/RackViewModel.swift e10dSynth/Audio/SynthEngine.swift
git commit -m "vm: rack viewmodel with drag-to-patch + module positioning"
```

---

### Task 14: Knob Component

**Files:**
- Create: `e10dSynth/Views/Components/KnobView.swift`

**Step 1: Implement KnobView**

`e10dSynth/Views/Components/KnobView.swift`:
```swift
import SwiftUI

struct KnobView: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    var unit: String = ""
    var size: CGFloat = 48

    @State private var lastY: CGFloat = 0
    @State private var isDragging = false

    private var normalizedValue: Float {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    private var displayValue: String {
        if abs(value) < 10 { return String(format: "%.2f\(unit)", value) }
        if abs(value) < 100 { return String(format: "%.1f\(unit)", value) }
        return String(format: "%.0f\(unit)", value)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.synthPanel)
                    .overlay(Circle().stroke(Color.synthBorder, lineWidth: 1))

                // Value arc
                Circle()
                    .trim(from: 0.15, to: 0.15 + CGFloat(normalizedValue) * 0.7)
                    .stroke(isDragging ? Color.synthAmber : Color.synthGreen,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(90 + 54))

                // Tick mark (pointer)
                let angle = Angle.degrees(-225 + Double(normalizedValue) * 270)
                Rectangle()
                    .fill(Color.synthGreen)
                    .frame(width: 1.5, height: size * 0.28)
                    .offset(y: -size * 0.18)
                    .rotationEffect(angle)
            }
            .frame(width: size, height: size)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            lastY = gesture.startLocation.y
                            isDragging = true
                        }
                        let delta = Float(lastY - gesture.location.y) / 200.0
                        lastY = gesture.location.y
                        value = min(range.upperBound, max(range.lowerBound, value + delta * (range.upperBound - range.lowerBound)))
                    }
                    .onEnded { _ in isDragging = false }
            )

            Text(label)
                .font(.synthLabel)
                .foregroundStyle(Color.synthText)

            Text(displayValue)
                .font(.synthMonoSm)
                .foregroundStyle(isDragging ? Color.synthAmber : Color.synthGreen)
                .monospacedDigit()
        }
    }
}

#Preview {
    @Previewable @State var val: Float = 0.5
    KnobView(label: "CUTOFF", value: $val, range: 20...20000, unit: "hz")
        .padding()
        .background(Color.synthBg)
}
```

**Step 2: Manual test — preview renders knob with arc and drag**

**Step 3: Commit**
```bash
git add e10dSynth/Views/Components/KnobView.swift
git commit -m "ui: knob component — drag vertically, value arc, crt style"
```

---

### Task 15: Module Card View

**Files:**
- Create: `e10dSynth/Views/Rack/ModuleCardView.swift`
- Create: `e10dSynth/Views/Rack/JackView.swift`

**Step 1: Implement JackView**

`e10dSynth/Views/Rack/JackView.swift`:
```swift
import SwiftUI

struct JackView: View {
    let jack: Jack
    let moduleId: String
    var isActive: Bool = false
    var onDragStart: ((JackRef, CGPoint) -> Void)?
    var onHover: ((JackRef?) -> Void)?

    @State private var globalPosition: CGPoint = .zero

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.signalColor(jack.signalType) : Color.synthPanel)
                .overlay(
                    Circle().stroke(Color.signalColor(jack.signalType), lineWidth: 1.5)
                )
                .frame(width: 16, height: 16)
                .overlay(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                let frame = geo.frame(in: .global)
                                globalPosition = CGPoint(x: frame.midX, y: frame.midY)
                            }
                    }
                )
        }
        .overlay(
            Text(jack.name)
                .font(.synthLabel)
                .foregroundStyle(Color.synthText)
                .fixedSize()
                .offset(x: jack.direction == .input ? -40 : 40)
        )
        .gesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged { g in
                    if g.translation == .zero {
                        let ref = JackRef(moduleId: moduleId, jackId: jack.id,
                                          signalType: jack.signalType, direction: jack.direction)
                        onDragStart?(ref, globalPosition)
                    }
                }
        )
    }
}
```

**Step 2: Implement ModuleCardView**

`e10dSynth/Views/Rack/ModuleCardView.swift`:
```swift
import SwiftUI

struct ModuleCardView: View {
    let module: any SynthModule
    @Bindable var vm: RackViewModel
    @State private var position: CGPoint

    init(module: any SynthModule, vm: RackViewModel) {
        self.module = module
        self.vm = vm
        _position = State(initialValue: vm.modulePositions[module.id] ?? .zero)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(module.name)
                .font(.synthMonoSm)
                .foregroundStyle(Color.synthGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.synthDimGreen)

            Divider().background(Color.synthBorder)

            // Jacks + knobs
            HStack(alignment: .top, spacing: 0) {
                // Input jacks (left)
                VStack(spacing: 8) {
                    ForEach(module.inputs) { jack in
                        JackView(jack: jack, moduleId: module.id) { ref, pt in
                            vm.startDrag(from: ref, at: pt)
                        }
                    }
                }
                .frame(width: 50)
                .padding(.vertical, 8)

                Divider().background(Color.synthBorder)

                // Module-specific controls (center)
                moduleControls
                    .frame(maxWidth: .infinity)
                    .padding(8)

                Divider().background(Color.synthBorder)

                // Output jacks (right)
                VStack(spacing: 8) {
                    ForEach(module.outputs) { jack in
                        JackView(jack: jack, moduleId: module.id) { ref, pt in
                            vm.startDrag(from: ref, at: pt)
                        }
                    }
                }
                .frame(width: 50)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 180)
        .background(Color.synthPanel)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.synthBorder, lineWidth: 1))
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { g in
                    position = g.location
                }
                .onEnded { g in
                    vm.moveModule(module.id, to: g.location)
                }
        )
    }

    @ViewBuilder
    private var moduleControls: some View {
        switch module.moduleType {
        case .vco:
            VCOControlsView(module: module as! VCOModule)
        case .vcf:
            VCFControlsView(module: module as! VCFModule)
        case .vca:
            VCAControlsView(module: module as! VCAModule)
        case .env:
            ENVControlsView(module: module as! ENVModule)
        case .lfo:
            LFOControlsView(module: module as! LFOModule)
        default:
            Text(module.name).font(.synthMono).foregroundStyle(Color.synthText)
        }
    }
}
```

**Step 3: Create module-specific control views**

`e10dSynth/Views/Rack/ModuleControlViews.swift`:
```swift
import SwiftUI

struct VCOControlsView: View {
    @Bindable var module: VCOModule
    var body: some View {
        VStack(spacing: 6) {
            Picker("Wave", selection: $module.waveform) {
                ForEach(VCOWaveform.allCases, id: \.self) {
                    Text($0.rawValue.prefix(3).uppercased()).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .tint(Color.synthGreen)
            HStack {
                KnobView(label: "TUNE", value: Binding(get: { module.tune }, set: { module.tune = $0 }), range: -24...24, unit: "st", size: 40)
                KnobView(label: "OCT", value: Binding(get: { Float(module.octave) }, set: { module.octave = Int($0) }), range: 0...8, size: 40)
            }
        }
    }
}

struct VCFControlsView: View {
    @Bindable var module: VCFModule
    var body: some View {
        HStack {
            KnobView(label: "CUTOFF", value: Binding(get: { module.cutoff }, set: { module.cutoff = $0 }), range: 20...20000, unit: "hz", size: 40)
            KnobView(label: "RES", value: Binding(get: { module.resonance }, set: { module.resonance = $0 }), range: 0...0.99, size: 40)
        }
    }
}

struct VCAControlsView: View {
    @Bindable var module: VCAModule
    var body: some View {
        KnobView(label: "GAIN", value: Binding(get: { module.gain }, set: { module.gain = $0 }), range: 0...2, size: 40)
    }
}

struct ENVControlsView: View {
    @Bindable var module: ENVModule
    var body: some View {
        HStack(spacing: 4) {
            KnobView(label: "A", value: Binding(get: { module.attack },  set: { module.attack = $0 }),  range: 0...4,   size: 34)
            KnobView(label: "D", value: Binding(get: { module.decay },   set: { module.decay = $0 }),   range: 0...4,   size: 34)
            KnobView(label: "S", value: Binding(get: { module.sustain }, set: { module.sustain = $0 }), range: 0...1,   size: 34)
            KnobView(label: "R", value: Binding(get: { module.release }, set: { module.release = $0 }), range: 0...4,   size: 34)
        }
    }
}

struct LFOControlsView: View {
    @Bindable var module: LFOModule
    var body: some View {
        HStack {
            KnobView(label: "RATE",  value: Binding(get: { module.rate },  set: { module.rate = $0 }),  range: 0.01...20, unit: "hz", size: 40)
            KnobView(label: "DEPTH", value: Binding(get: { module.depth }, set: { module.depth = $0 }), range: 0...1,     size: 40)
        }
    }
}
```

**Step 4: Commit**
```bash
git add e10dSynth/Views/
git commit -m "ui: module cards with jack views + per-module knob controls"
```

---

### Task 16: Patch Cable Overlay

**Files:**
- Create: `e10dSynth/Views/Rack/PatchCableOverlay.swift`

**Step 1: Implement cable drawing**

`e10dSynth/Views/Rack/PatchCableOverlay.swift`:
```swift
import SwiftUI

struct PatchCableOverlay: View {
    let patches: [Patch]
    let jackPositions: [String: CGPoint]
    let draggingFrom: JackRef?
    let draggingPoint: CGPoint
    let onRemovePatch: (UUID) -> Void

    var body: some View {
        Canvas { ctx, size in
            // Draw existing cables
            for patch in patches {
                let srcKey = "\(patch.fromModuleId).\(patch.fromJackId)"
                let dstKey = "\(patch.toModuleId).\(patch.toJackId)"
                guard let src = jackPositions[srcKey],
                      let dst = jackPositions[dstKey] else { continue }

                // Determine color from signal type
                let color = patchColor(patch: patch)
                drawCable(ctx: ctx, from: src, to: dst, color: color)
            }

            // Draw in-progress drag cable
            if let from = draggingFrom,
               let srcPos = jackPositions["\(from.moduleId).\(from.jackId)"] {
                drawCable(ctx: ctx, from: srcPos, to: draggingPoint,
                          color: Color.signalColor(from.signalType).opacity(0.6),
                          dashed: true)
            }
        }
        // Tap to delete cables
        .onTapGesture { point in
            if let patch = nearestPatch(to: point) {
                onRemovePatch(patch.id)
            }
        }
        .allowsHitTesting(draggingFrom == nil)
    }

    private func drawCable(ctx: GraphicsContext, from: CGPoint, to: CGPoint, color: Color, dashed: Bool = false) {
        let cp1 = CGPoint(x: from.x + 80, y: from.y)
        let cp2 = CGPoint(x: to.x - 80, y: to.y)
        var path = Path()
        path.move(to: from)
        path.addCurve(to: to, control1: cp1, control2: cp2)

        var stroke = ctx.resolve(GraphicsContext.Shading.color(color))
        if dashed {
            ctx.stroke(path, with: stroke,
                       style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
        } else {
            ctx.stroke(path, with: stroke,
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }

    private func patchColor(patch: Patch) -> Color {
        // Look up signal type from jack ID convention
        // (audio jacks contain "audio", cv jacks contain "cv", gate contains "gate")
        if patch.fromJackId.contains("audio") { return Color.synthGreen }
        if patch.fromJackId.contains("cv")    { return Color.synthAmber }
        return Color.synthRed  // gate
    }

    private func nearestPatch(to point: CGPoint) -> Patch? {
        for patch in patches {
            let srcKey = "\(patch.fromModuleId).\(patch.fromJackId)"
            let dstKey = "\(patch.toModuleId).\(patch.toJackId)"
            guard let src = jackPositions[srcKey], let dst = jackPositions[dstKey] else { continue }
            // Sample bezier at several points and check distance
            for t in stride(from: 0.0, through: 1.0, by: 0.05) {
                let cp1 = CGPoint(x: src.x + 80, y: src.y)
                let cp2 = CGPoint(x: dst.x - 80, y: dst.y)
                let pt = bezierPoint(t: t, p0: src, p1: cp1, p2: cp2, p3: dst)
                if hypot(pt.x - point.x, pt.y - point.y) < 12 { return patch }
            }
        }
        return nil
    }

    private func bezierPoint(t: Double, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let mt = 1 - t
        let x = mt*mt*mt*p0.x + 3*mt*mt*t*p1.x + 3*mt*t*t*p2.x + t*t*t*p3.x
        let y = mt*mt*mt*p0.y + 3*mt*mt*t*p1.y + 3*mt*t*t*p2.y + t*t*t*p3.y
        return CGPoint(x: x, y: y)
    }
}
```

**Step 2: Commit**
```bash
git add e10dSynth/Views/Rack/PatchCableOverlay.swift
git commit -m "ui: patch cable overlay with bezier curves, drag preview, tap-to-delete"
```

---

### Task 17: Rack Canvas View

**Files:**
- Create: `e10dSynth/Views/Rack/RackView.swift`

**Step 1: Implement RackView**

`e10dSynth/Views/Rack/RackView.swift`:
```swift
import SwiftUI

struct RackView: View {
    @Environment(SynthEngine.self) var engine
    @State private var vm: RackViewModel
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showAddModule = false

    init(engine: SynthEngine) {
        _vm = State(initialValue: RackViewModel(engine: engine))
    }

    var body: some View {
        ZStack {
            // Background grid
            GridBackground()

            // Canvas: modules + cables
            ZStack {
                // Cables layer (below modules)
                PatchCableOverlay(
                    patches: vm.graph.patches,
                    jackPositions: vm.jackPositions,
                    draggingFrom: vm.draggingFromJack,
                    draggingPoint: vm.draggingPoint,
                    onRemovePatch: vm.removePatch
                )

                // Module cards
                ForEach(vm.moduleOrder, id: \.self) { moduleId in
                    if let module = vm.graph.modules[moduleId] {
                        ModuleCardView(module: module, vm: vm)
                    }
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { val in scale = max(0.3, min(2.5, val)) },
                    DragGesture()
                        .onChanged { g in
                            if vm.draggingFromJack != nil {
                                vm.updateDrag(to: g.location)
                            } else {
                                offset = g.translation
                            }
                        }
                        .onEnded { g in
                            if vm.draggingFromJack != nil {
                                vm.endDrag(at: g.location)
                            }
                        }
                )
            )

            // Add module button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showAddModule = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(Color.synthGreen)
                            .frame(width: 48, height: 48)
                            .background(Color.synthPanel)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.synthBorder))
                    }
                    .padding()
                }
            }
        }
        .background(Color.synthBg)
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddModule) {
            AddModuleSheet { type in
                vm.addModule(type)
                showAddModule = false
            }
        }
    }
}

struct GridBackground: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 24
            var path = Path()
            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    path.addEllipse(in: CGRect(x: x - 0.75, y: y - 0.75, width: 1.5, height: 1.5))
                    y += spacing
                }
                x += spacing
            }
            ctx.fill(path, with: .color(Color.synthGrid))
        }
        .ignoresSafeArea()
    }
}

struct AddModuleSheet: View {
    let onSelect: (ModuleType) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ADD MODULE")
                .font(.synthMonoLg)
                .foregroundStyle(Color.synthGreen)
                .padding()
            Divider().background(Color.synthBorder)
            ForEach(ModuleType.allCases, id: \.self) { type in
                Button {
                    onSelect(type)
                } label: {
                    Text(type.rawValue.uppercased())
                        .font(.synthMono)
                        .foregroundStyle(Color.synthText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                Divider().background(Color.synthBorder)
            }
        }
        .background(Color.synthBg)
        .presentationDetents([.medium])
    }
}
```

**Step 2: Manual test**
Build + run on simulator. Should see dot-grid background with 4 default modules (VCO, VCF, VCA, OUT) arranged in a row. Drag module to reposition. Tap + to add a new module.

**Step 3: Commit**
```bash
git add e10dSynth/Views/Rack/
git commit -m "ui: rack canvas — scrollable/zoomable with modules, grid bg, add sheet"
```

---

### Task 18: Sequencer View

**Files:**
- Create: `e10dSynth/Views/Sequencer/SequencerView.swift`
- Create: `e10dSynth/Views/Sequencer/StepCellView.swift`
- Create: `e10dSynth/Views/Sequencer/TrackRowView.swift`
- Create: `e10dSynth/Views/Sequencer/TransportBar.swift`

**Step 1: TransportBar**

`e10dSynth/Views/Sequencer/TransportBar.swift`:
```swift
import SwiftUI

struct TransportBar: View {
    @Bindable var vm: SequencerViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Play/Stop
            Button {
                vm.isPlaying ? vm.stop() : vm.play()
            } label: {
                Image(systemName: vm.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title3)
                    .foregroundStyle(vm.isPlaying ? Color.synthAmber : Color.synthGreen)
            }

            Divider().frame(height: 24).background(Color.synthBorder)

            // BPM
            VStack(spacing: 2) {
                Text("BPM").font(.synthLabel).foregroundStyle(Color.synthText)
                HStack(spacing: 4) {
                    Button { vm.clock.bpm = max(20, vm.clock.bpm - 1) } label: {
                        Text("−").font(.synthMono).foregroundStyle(Color.synthGreen)
                    }
                    Text(String(format: "%.0f", vm.clock.bpm))
                        .font(.synthMonoLg).foregroundStyle(Color.synthGreen).monospacedDigit()
                        .frame(width: 48)
                    Button { vm.clock.bpm = min(250, vm.clock.bpm + 1) } label: {
                        Text("+").font(.synthMono).foregroundStyle(Color.synthGreen)
                    }
                }
            }

            Divider().frame(height: 24).background(Color.synthBorder)

            // Swing
            VStack(spacing: 2) {
                Text("SWING").font(.synthLabel).foregroundStyle(Color.synthText)
                Slider(value: $vm.clock.swing, in: 0...100)
                    .tint(Color.synthAmber)
                    .frame(width: 80)
            }

            Spacer()

            // Pattern selector (4×4)
            PatternGrid(vm: vm)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.synthPanel)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.synthBorder), alignment: .bottom)
    }
}

struct PatternGrid: View {
    @Bindable var vm: SequencerViewModel
    var body: some View {
        LazyVGrid(columns: Array(repeating: .init(.fixed(28)), count: 4), spacing: 4) {
            ForEach(0..<16) { i in
                Button {
                    vm.activePatternIndex = i
                } label: {
                    Text(vm.patterns[i].name)
                        .font(.synthLabel)
                        .foregroundStyle(vm.activePatternIndex == i ? Color.synthBg : Color.synthText)
                        .frame(width: 26, height: 20)
                        .background(vm.activePatternIndex == i ? Color.synthGreen : Color.synthDimGreen)
                }
            }
        }
    }
}
```

**Step 2: StepCellView**

`e10dSynth/Views/Sequencer/StepCellView.swift`:
```swift
import SwiftUI

struct StepCellView: View {
    @Binding var step: Step
    let isCurrent: Bool
    var onLongPress: (() -> Void)?

    var body: some View {
        Rectangle()
            .fill(cellColor)
            .overlay(
                Rectangle()
                    .stroke(isCurrent ? Color.synthAmber : Color.synthBorder, lineWidth: isCurrent ? 2 : 0.5)
            )
            .frame(width: 32, height: 28)
            .onTapGesture { step.isOn.toggle() }
            .onLongPressGesture { onLongPress?() }
    }

    private var cellColor: Color {
        if !step.isOn { return Color.synthDimGreen.opacity(0.5) }
        if step.isAccent { return Color.synthAmber }
        return Color.synthGreen
    }
}
```

**Step 3: TrackRowView**

`e10dSynth/Views/Sequencer/TrackRowView.swift`:
```swift
import SwiftUI

struct TrackRowView: View {
    @Binding var track: Track
    let currentStep: Int
    let isPlaying: Bool
    @State private var editingStep: Step? = nil
    @State private var editingStepIndex: Int? = nil

    var body: some View {
        HStack(spacing: 0) {
            // Track header
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.synthLabel).foregroundStyle(Color.synthGreen).lineLimit(1)
                HStack(spacing: 6) {
                    MuteButton(isMuted: $track.isMuted)
                    SoloButton(isSolo: $track.isSolo)
                }
            }
            .frame(width: 72)
            .padding(.horizontal, 6)

            Divider().frame(height: 36).background(Color.synthBorder)

            // Step cells
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(track.steps.indices, id: \.self) { i in
                        StepCellView(
                            step: $track.steps[i],
                            isCurrent: isPlaying && i == currentStep % track.steps.count
                        ) {
                            editingStepIndex = i
                            editingStep = track.steps[i]
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(height: 36)
        .popover(item: $editingStep) { step in
            StepEditPopover(
                step: Binding(
                    get: { editingStep ?? step },
                    set: { newStep in
                        editingStep = newStep
                        if let idx = editingStepIndex {
                            track.steps[idx] = newStep
                        }
                    }
                )
            )
        }
    }
}

struct MuteButton: View {
    @Binding var isMuted: Bool
    var body: some View {
        Button { isMuted.toggle() } label: {
            Text("M").font(.synthLabel)
                .foregroundStyle(isMuted ? Color.synthBg : Color.synthAmber)
                .frame(width: 14, height: 12)
                .background(isMuted ? Color.synthAmber : .clear)
        }
    }
}

struct SoloButton: View {
    @Binding var isSolo: Bool
    var body: some View {
        Button { isSolo.toggle() } label: {
            Text("S").font(.synthLabel)
                .foregroundStyle(isSolo ? Color.synthBg : Color.synthGreen)
                .frame(width: 14, height: 12)
                .background(isSolo ? Color.synthGreen : .clear)
        }
    }
}

struct StepEditPopover: View {
    @Binding var step: Step
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STEP EDIT").font(.synthMono).foregroundStyle(Color.synthGreen)
            LabeledStepper(label: "NOTE", value: $step.note, range: 0...127)
            LabeledStepper(label: "VEL",  value: $step.velocity, range: 0...127)
            VStack(alignment: .leading) {
                Text("PROB").font(.synthLabel).foregroundStyle(Color.synthText)
                Slider(value: $step.probability, in: 0...1).tint(Color.synthGreen)
            }
            Toggle("ACCENT", isOn: $step.isAccent).tint(Color.synthAmber).font(.synthMono).foregroundStyle(Color.synthText)
        }
        .padding()
        .background(Color.synthPanel)
        .frame(width: 240)
    }
}

struct LabeledStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var body: some View {
        HStack {
            Text(label).font(.synthLabel).foregroundStyle(Color.synthText).frame(width: 40)
            Stepper("\(value)", value: $value, in: range)
                .font(.synthMono).foregroundStyle(Color.synthGreen)
        }
    }
}

extension Step: Identifiable {}
```

**Step 4: SequencerView**

`e10dSynth/Views/Sequencer/SequencerView.swift`:
```swift
import SwiftUI

struct SequencerView: View {
    @Environment(SynthEngine.self) var engine
    @State private var vm: SequencerViewModel

    init(engine: SynthEngine) {
        _vm = State(initialValue: SequencerViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            TransportBar(vm: vm)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach($vm.activePattern.tracks) { $track in
                        TrackRowView(
                            track: $track,
                            currentStep: vm.currentStep,
                            isPlaying: vm.isPlaying
                        )
                        Divider().background(Color.synthBorder)
                    }
                }
            }
        }
        .background(Color.synthBg)
        .onAppear {
            vm.synthEngine = engine
            vm.midiEngine = engine.midiEngineInstance
        }
    }
}
```

**Step 5: Manual test**
Build + run. Navigate to Seq tab. See 8 track rows with 16 step cells each. Tap cells to toggle on/off (green). Tap play — current step indicator moves across cells at the set BPM.

**Step 6: Commit**
```bash
git add e10dSynth/Views/Sequencer/
git commit -m "ui: sequencer view — transport bar, step grid, track rows, step edit popover"
```

---

### Task 19: MIDI Routing View

**Files:**
- Create: `e10dSynth/Views/MIDI/MIDIRoutingView.swift`

**Step 1: Implement MIDIRoutingView**

`e10dSynth/Views/MIDI/MIDIRoutingView.swift`:
```swift
import SwiftUI

struct MIDIRoutingView: View {
    @Environment(SynthEngine.self) var engine

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader("CLOCK")
                clockSection

                Divider().background(Color.synthBorder)

                SectionHeader("CHANNELS")
                channelSection

                Divider().background(Color.synthBorder)

                SectionHeader("CC MAPPINGS")
                ccMappingsSection
            }
        }
        .background(Color.synthBg)
    }

    private var clockSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Source", selection: .constant("Internal")) {
                Text("Internal").tag("Internal")
                Text("MIDI In").tag("MIDI In")
            }
            .pickerStyle(.segmented)
            .tint(Color.synthGreen)
        }
        .padding()
    }

    private var channelSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            MIDIChannelRow(label: "RECEIVE",
                           value: Binding(get: { engine.midiEngineInstance.receiveChannel },
                                          set: { engine.midiEngineInstance.receiveChannel = $0 }))
            Divider().background(Color.synthBorder)
            MIDIChannelRow(label: "SEND",
                           value: Binding(get: { engine.midiEngineInstance.sendChannel },
                                          set: { engine.midiEngineInstance.sendChannel = $0 }))
        }
    }

    private var ccMappingsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Long-press any knob to enter MIDI Learn mode.\nWiggle a CC to map it.")
                .font(.synthMonoSm)
                .foregroundStyle(Color.synthText)
                .padding()
        }
    }
}

struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.synthLabel)
            .foregroundStyle(Color.synthText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.synthDimGreen.opacity(0.4))
    }
}

struct MIDIChannelRow: View {
    let label: String
    @Binding var value: Int
    var body: some View {
        HStack {
            Text(label).font(.synthMono).foregroundStyle(Color.synthText)
            Spacer()
            Stepper("CH \(value)", value: $value, in: 1...16)
                .font(.synthMono).foregroundStyle(Color.synthGreen)
        }
        .padding()
    }
}
```

**Step 2: Commit**
```bash
git add e10dSynth/Views/MIDI/
git commit -m "ui: midi routing view — clock source, channels, cc learn hint"
```

---

### Task 20: Tab Bar + App Integration

**Files:**
- Modify: `e10dSynth/App/ContentView.swift`

**Step 1: Update ContentView with TabView**

Replace contents of `e10dSynth/App/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    @Environment(SynthEngine.self) var engine

    var body: some View {
        TabView {
            RackView(engine: engine)
                .tabItem {
                    Label("Rack", systemImage: "hexagon")
                }

            SequencerView(engine: engine)
                .tabItem {
                    Label("Seq", systemImage: "grid")
                }

            MIDIRoutingView()
                .tabItem {
                    Label("MIDI", systemImage: "arrow.left.arrow.right")
                }
        }
        .tint(Color.synthGreen)
        .onAppear { engine.start() }
        .toolbarBackground(Color.synthPanel, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
```

**Step 2: Add `midiEngineInstance` to SynthEngine**

Add to `SynthEngine`:
```swift
let midiEngineInstance = MIDIEngine()
```

Wire up MIDI callbacks in `SynthEngine.init()`:
```swift
midiEngineInstance.onNoteOn = { [weak self] note, vel in
    self?.noteOn(note: note, velocity: vel)
}
midiEngineInstance.onNoteOff = { [weak self] note in
    self?.noteOff(note: note)
}
```

**Step 3: Manual test — full integration**
Build + run on device or simulator.
- Tab 1 (Rack): see modules with patch cables, drag to rearrange
- Tab 2 (Seq): tap play, hear sequencer output, step indicator moves
- Tab 3 (MIDI): see routing panel

**Step 4: Commit**
```bash
git add e10dSynth/App/ContentView.swift e10dSynth/Audio/SynthEngine.swift
git commit -m "app: three-tab navigation — rack, sequencer, midi"
```

---

### Task 21: Preset Save/Load

**Files:**
- Create: `e10dSynth/Presets/PresetManager.swift`
- Create: `e10dSynthTests/PresetManagerTests.swift`

**Step 1: Write failing tests**

`e10dSynthTests/PresetManagerTests.swift`:
```swift
import XCTest
@testable import e10dSynth

final class PresetManagerTests: XCTestCase {

    func testSaveAndLoadPreset() throws {
        let manager = PresetManager()
        let vm = SequencerViewModel()
        vm.activePattern.tracks[0].toggleStep(at: 0)
        vm.activePattern.tracks[0].toggleStep(at: 4)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.e10d")
        try manager.save(vm: vm, to: url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let loaded = try manager.load(from: url)
        XCTAssertTrue(loaded.patterns[0].tracks[0].steps[0].isOn)
        XCTAssertTrue(loaded.patterns[0].tracks[0].steps[4].isOn)
        XCTAssertFalse(loaded.patterns[0].tracks[0].steps[1].isOn)
    }
}
```

**Step 2: Implement PresetManager**

`e10dSynth/Presets/PresetManager.swift`:
```swift
import Foundation

struct SynthPreset: Codable {
    let patterns: [Pattern]
    let activePatternIndex: Int
    let bpm: Double
    let swing: Double
    let graphPreset: GraphPreset
}

final class PresetManager {
    static let shared = PresetManager()

    func save(vm: SequencerViewModel, to url: URL) throws {
        let preset = SynthPreset(
            patterns: vm.patterns,
            activePatternIndex: vm.activePatternIndex,
            bpm: vm.clock.bpm,
            swing: vm.clock.swing,
            graphPreset: GraphPreset(patches: [], modulePositions: [:])  // TODO: include graph
        )
        let data = try JSONEncoder().encode(preset)
        try data.write(to: url, options: .atomic)
    }

    func load(from url: URL) throws -> SequencerViewModel {
        let data = try Data(contentsOf: url)
        let preset = try JSONDecoder().decode(SynthPreset.self, from: data)
        let vm = SequencerViewModel()
        vm.patterns = preset.patterns
        vm.activePatternIndex = preset.activePatternIndex
        vm.clock.bpm = preset.bpm
        vm.clock.swing = preset.swing
        return vm
    }

    func presetDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func listPresets() -> [URL] {
        let dir = presetDirectory()
        return (try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "e10d" }) ?? []
    }
}
```

**Step 3: Run tests**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: PASS.

**Step 4: Commit**
```bash
git add e10dSynth/Presets/ e10dSynthTests/PresetManagerTests.swift
git commit -m "presets: save/load .e10d json bundles with patterns + bpm"
```

---

### Task 22: Final Polish

**Files:**
- Create: `e10dSynth/Assets.xcassets/AppIcon.appiconset/` (via Xcode)

**Step 1: App icon — create 1024×1024 in Xcode Asset Catalog**
- Background: `#0a0a0a`
- Symbol: stylized hexagonal grid + waveform in `#00ff88`
- Add via Xcode's Asset Catalog editor (drag PNG into AppIcon slot)

**Step 2: Accessibility — minimum touch targets**
Ensure all buttons/jacks are at least 44×44pt tap area. Wrap small elements in `.contentShape(Rectangle().size(CGSize(width: 44, height: 44)))` where needed.

**Step 3: Add haptic feedback to step cells**

In `StepCellView.onTapGesture`:
```swift
.onTapGesture {
    step.isOn.toggle()
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
}
```

**Step 4: Run all tests**
```bash
xcodebuild test -scheme e10dSynth -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(Test Suite|PASS|FAIL|error:)" | tail -20
```
Expected: all PASS, no errors.

**Step 5: Final commit**
```bash
git add .
git commit -m "polish: haptics, touch targets, app icon placeholder"
```

---

## Unresolved Questions

1. **AudioKit dynamic reconnection** — MoogLadder/Fader don't support live input swapping. Current approach: stop engine → rewire → restart. Is a brief audio dropout on patch acceptable, or do we need a crossfade mixer approach?

2. **LFO → parameter CV** — LFO outputs a CV signal conceptually, but AudioKit doesn't route audio-rate signals to parameters. Do we poll the LFO oscillator's output sample value on a timer and apply it as a parameter automation, or use a different modulation approach?

3. **SEQ module in graph** — Currently `SequencerViewModel` is separate from `ModularGraph`. Should the SEQ appear as a module card in the rack view (with gate/CV outputs you can patch to VCO/VCA), or keep it as a separate tab only?

4. **Ableton Link** — The design mentions Ableton Link clock sync. Should this be in the MVP or deferred? Requires `ABLinkKit` framework integration.

5. **iPad layout** — Should the iPad show Rack + Sequencer side-by-side in a split view, or is the tab bar sufficient for MVP?
