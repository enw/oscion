import SwiftUI

// MARK: - Main View

struct SynthView: View {
    @Environment(SynthEngine.self) var engine
    @State private var seqVM = SequencerViewModel()

    // VCO
    @State private var waveform: VCOWaveform = .sawtooth
    @State private var tune: Float = 0

    // VCF
    @State private var cutoff: Float = 1000
    @State private var resonance: Float = 0.5

    // ENV
    @State private var attack: Float = 0.01
    @State private var decay: Float = 0.1
    @State private var sustain: Float = 0.8
    @State private var envRelease: Float = 0.3

    // OUT
    @State private var level: Float = 0.8

    // Seq
    @State private var selectedStep: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.synthBorder)
            panels
            Divider().background(Color.synthBorder)
            sequencerFooter
        }
        .background(Color.synthBg)
        .onAppear {
            seqVM.synthEngine = engine
            seqVM.midiEngine = engine.midiEngineInstance
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("e10d")
                .font(.system(.title, design: .monospaced).weight(.bold))
                .foregroundStyle(Color.synthGreen)
            Circle()
                .fill(engine.isRunning ? Color.synthGreen : Color.synthDimGreen)
                .frame(width: 6, height: 6)
                .padding(.leading, 4)
            Spacer()
            Text("ANALOG SYNTH")
                .font(.synthLabel)
                .foregroundStyle(Color.synthText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.synthPanel)
    }

    // MARK: Module Panels

    private var panels: some View {
        VStack(spacing: 0) {
            moduleRow("VCO") {
                VStack(spacing: 10) {
                    WaveformPicker(selection: $waveform)
                        .onChange(of: waveform) { _, v in engine.vco.waveform = v }
                    KnobView(
                        label: "TUNE",
                        value: Binding(get: { tune }, set: { tune = $0; engine.vco.tune = $0 }),
                        range: -24...24, unit: "st", size: 52
                    )
                }
            }

            Divider().background(Color.synthBorder)

            moduleRow("VCF") {
                HStack(spacing: 24) {
                    KnobView(
                        label: "CUT",
                        value: Binding(get: { cutoff }, set: { cutoff = $0; engine.vcf.cutoff = $0 }),
                        range: 20...20000, unit: "hz", size: 52
                    )
                    KnobView(
                        label: "RES",
                        value: Binding(get: { resonance }, set: { resonance = $0; engine.vcf.resonance = $0 }),
                        range: 0...0.99, size: 52
                    )
                }
            }

            Divider().background(Color.synthBorder)

            moduleRow("ENV") {
                VStack(spacing: 6) {
                    HStack(spacing: 24) {
                        KnobView(
                            label: "ATK",
                            value: Binding(get: { attack },  set: { attack = $0;  engine.env.attack = $0 }),
                            range: 0...4, unit: "s", size: 44
                        )
                        KnobView(
                            label: "DEC",
                            value: Binding(get: { decay },   set: { decay = $0;   engine.env.decay = $0 }),
                            range: 0...4, unit: "s", size: 44
                        )
                        KnobView(
                            label: "SUS",
                            value: Binding(get: { sustain }, set: { sustain = $0; engine.env.sustain = $0 }),
                            range: 0...1, size: 44
                        )
                        KnobView(
                            label: "REL",
                            value: Binding(get: { envRelease }, set: { envRelease = $0; engine.env.release = $0 }),
                            range: 0...4, unit: "s", size: 44
                        )
                    }
                }
            }

            Divider().background(Color.synthBorder)

            moduleRow("OUT") {
                KnobView(
                    label: "VOL",
                    value: Binding(get: { level }, set: { level = $0; engine.out.level = $0 }),
                    range: 0...1, size: 52
                )
            }
        }
    }

    @ViewBuilder
    private func moduleRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.synthLabel)
                .foregroundStyle(Color.synthText)
                .frame(width: 36, alignment: .leading)
                .padding(.leading, 16)

            Rectangle()
                .fill(Color.synthBorder)
                .frame(width: 1)
                .padding(.vertical, 12)

            content()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity)
        .background(Color.synthBg)
    }

    // MARK: Sequencer Footer

    private var sequencerFooter: some View {
        VStack(spacing: 8) {
            stepGrid
            stepNoteEditor
            transport
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.synthPanel)
    }

    private var stepGrid: some View {
        let steps = seqVM.activePattern.tracks[0].steps
        return VStack(spacing: 4) {
            stepRow(steps: steps, range: 0..<8)
            stepRow(steps: steps, range: 8..<16)
        }
    }

    @ViewBuilder
    private func stepRow(steps: [Step], range: Range<Int>) -> some View {
        HStack(spacing: 3) {
            ForEach(range, id: \.self) { i in
                let isOn = steps[i].isOn
                let isCurrent = seqVM.isPlaying && seqVM.currentStep == i
                let isSelected = selectedStep == i
                Button {
                    seqVM.activePattern.tracks[0].toggleStep(at: i)
                    selectedStep = isSelected ? nil : i
                } label: {
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(isCurrent ? Color.synthAmber :
                                  isOn      ? Color.synthGreen :
                                              Color.synthDimGreen)
                            .frame(height: 24)
                            .overlay(
                                Rectangle()
                                    .stroke(isSelected ? Color.synthAmber : Color.synthBorder, lineWidth: isSelected ? 1 : 0.5)
                            )
                        Text(noteName(steps[i].note))
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundStyle(isOn ? Color.synthGreen : Color.synthText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var stepNoteEditor: some View {
        if let s = selectedStep {
            let note = seqVM.activePattern.tracks[0].steps[s].note
            HStack(spacing: 8) {
                Text("STEP \(s + 1)")
                    .font(.synthLabel)
                    .foregroundStyle(Color.synthText)
                Spacer()
                Text("NOTE")
                    .font(.synthLabel)
                    .foregroundStyle(Color.synthText)
                stepperButtons(
                    value: Binding(
                        get: { seqVM.activePattern.tracks[0].steps[s].note },
                        set: { seqVM.activePattern.tracks[0].steps[s].note = $0 }
                    ),
                    range: 0...127,
                    label: noteName(note)
                )
            }
            .padding(.horizontal, 4)
            .transition(.opacity)
        }
    }

    private var transport: some View {
        HStack(spacing: 0) {
            // Play / Stop
            Button {
                seqVM.isPlaying ? seqVM.stop() : seqVM.play()
            } label: {
                Image(systemName: seqVM.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title3)
                    .foregroundStyle(seqVM.isPlaying ? Color.synthAmber : Color.synthGreen)
                    .frame(width: 40, height: 32)
                    .background(Color.synthDimGreen.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)

            Spacer()

            // BPM control
            HStack(spacing: 6) {
                Text("BPM").font(.synthLabel).foregroundStyle(Color.synthText)
                stepperButtons(
                    value: Binding(
                        get: { Int(seqVM.clock.bpm) },
                        set: { seqVM.clock.bpm = Double($0) }
                    ),
                    range: 20...250,
                    label: "\(Int(seqVM.clock.bpm))"
                )
            }
        }
    }

    @ViewBuilder
    private func stepperButtons(value: Binding<Int>, range: ClosedRange<Int>, label: String) -> some View {
        HStack(spacing: 0) {
            Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) } label: {
                Text("−").font(.synthMono).foregroundStyle(Color.synthGreen)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            Text(label)
                .font(.synthMonoSm)
                .foregroundStyle(Color.synthGreen)
                .monospacedDigit()
                .frame(minWidth: 36)

            Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) } label: {
                Text("+").font(.synthMono).foregroundStyle(Color.synthGreen)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .background(Color.synthDimGreen.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func noteName(_ midi: Int) -> String {
        let names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        let octave = (midi / 12) - 1
        return "\(names[midi % 12])\(octave)"
    }
}

// MARK: - Waveform Picker

struct WaveformPicker: View {
    @Binding var selection: VCOWaveform

    private let symbols: [(VCOWaveform, String)] = [
        (.sine,     "SINE"),
        (.sawtooth, "SAW"),
        (.square,   "SQR"),
        (.triangle, "TRI"),
    ]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(symbols, id: \.0) { wf, label in
                let active = selection == wf
                Button { selection = wf } label: {
                    Text(label)
                        .font(.synthLabel)
                        .foregroundStyle(active ? Color.synthBg : Color.synthText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(active ? Color.synthGreen : Color.synthDimGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }
}
