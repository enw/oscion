import SwiftUI

// MARK: - VCO Controls
struct VCOControlsView: View {
    let module: VCOModule
    @State private var tune: Float
    @State private var octaveF: Float
    @State private var waveform: VCOWaveform

    init(module: VCOModule) {
        self.module = module
        _tune = State(initialValue: module.tune)
        _octaveF = State(initialValue: Float(module.octave))
        _waveform = State(initialValue: module.waveform)
    }

    var body: some View {
        VStack(spacing: 6) {
            Picker("", selection: $waveform) {
                ForEach(VCOWaveform.allCases, id: \.self) { w in
                    Text(String(w.rawValue.prefix(3)).uppercased()).tag(w)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: waveform) { _, new in module.waveform = new }

            HStack(spacing: 8) {
                KnobView(label: "TUNE",
                         value: Binding(get: { tune }, set: { tune = $0; module.tune = $0 }),
                         range: -24...24, unit: "st", size: 38)
                KnobView(label: "OCT",
                         value: Binding(get: { octaveF }, set: { octaveF = $0; module.octave = Int($0) }),
                         range: 0...8, size: 38)
            }
        }
    }
}

// MARK: - VCF Controls
struct VCFControlsView: View {
    let module: VCFModule
    @State private var cutoff: Float
    @State private var resonance: Float

    init(module: VCFModule) {
        self.module = module
        _cutoff = State(initialValue: module.cutoff)
        _resonance = State(initialValue: module.resonance)
    }

    var body: some View {
        HStack(spacing: 8) {
            KnobView(label: "CUT",
                     value: Binding(get: { cutoff }, set: { cutoff = $0; module.cutoff = $0 }),
                     range: 20...20000, unit: "hz", size: 38)
            KnobView(label: "RES",
                     value: Binding(get: { resonance }, set: { resonance = $0; module.resonance = $0 }),
                     range: 0...0.99, size: 38)
        }
    }
}

// MARK: - VCA Controls
struct VCAControlsView: View {
    let module: VCAModule
    @State private var gain: Float

    init(module: VCAModule) {
        self.module = module
        _gain = State(initialValue: module.gain)
    }

    var body: some View {
        KnobView(label: "GAIN",
                 value: Binding(get: { gain }, set: { gain = $0; module.gain = $0 }),
                 range: 0...2, size: 44)
    }
}

// MARK: - ENV Controls
struct ENVControlsView: View {
    let module: ENVModule
    @State private var attack: Float
    @State private var decay: Float
    @State private var sustain: Float
    @State private var release: Float

    init(module: ENVModule) {
        self.module = module
        _attack  = State(initialValue: module.attack)
        _decay   = State(initialValue: module.decay)
        _sustain = State(initialValue: module.sustain)
        _release = State(initialValue: module.release)
    }

    var body: some View {
        HStack(spacing: 3) {
            KnobView(label: "A", value: Binding(get: { attack },  set: { attack = $0;  module.attack = $0 }),  range: 0...4, size: 32)
            KnobView(label: "D", value: Binding(get: { decay },   set: { decay = $0;   module.decay = $0 }),   range: 0...4, size: 32)
            KnobView(label: "S", value: Binding(get: { sustain }, set: { sustain = $0; module.sustain = $0 }), range: 0...1, size: 32)
            KnobView(label: "R", value: Binding(get: { release }, set: { release = $0; module.release = $0 }), range: 0...4, size: 32)
        }
    }
}

// MARK: - LFO Controls
struct LFOControlsView: View {
    let module: LFOModule
    @State private var rate: Float
    @State private var depth: Float

    init(module: LFOModule) {
        self.module = module
        _rate  = State(initialValue: module.rate)
        _depth = State(initialValue: module.depth)
    }

    var body: some View {
        HStack(spacing: 8) {
            KnobView(label: "RATE",  value: Binding(get: { rate },  set: { rate = $0;  module.rate = $0 }),  range: 0.01...20, unit: "hz", size: 38)
            KnobView(label: "DEPTH", value: Binding(get: { depth }, set: { depth = $0; module.depth = $0 }), range: 0...1,     size: 38)
        }
    }
}
