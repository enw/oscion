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
            HStack {
                Text(track.name.uppercased())
                    .font(.synthMonoLg).foregroundStyle(Color.synthGreen)
                Spacer()
                Button("DONE") { dismiss() }
                    .font(.synthMono).foregroundStyle(Color.synthAmber)
            }
            .padding()

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

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OCTAVE").font(.synthLabel).foregroundStyle(Color.synthText)
                        Stepper("\(track.voiceSettings.octave)", value: $track.voiceSettings.octave, in: 0...8)
                            .font(.synthMono).foregroundStyle(Color.synthGreen)
                    }
                    KnobView(label: "TUNE", value: $track.voiceSettings.tune, range: -24...24, unit: "st")
                }

                Text("FILTER").font(.synthLabel).foregroundStyle(Color.synthText)
                HStack(spacing: 16) {
                    KnobView(label: "CUTOFF", value: $track.voiceSettings.cutoff, range: 20...20000, unit: "Hz")
                    KnobView(label: "RES", value: $track.voiceSettings.resonance, range: 0...0.99)
                }

                Text("ENVELOPE").font(.synthLabel).foregroundStyle(Color.synthText)
                HStack(spacing: 12) {
                    KnobView(label: "A", value: $track.voiceSettings.attack,  range: 0...4, unit: "s")
                    KnobView(label: "D", value: $track.voiceSettings.decay,   range: 0...4, unit: "s")
                    KnobView(label: "S", value: $track.voiceSettings.sustain, range: 0...1)
                    KnobView(label: "R", value: $track.voiceSettings.release, range: 0...4, unit: "s")
                }

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
