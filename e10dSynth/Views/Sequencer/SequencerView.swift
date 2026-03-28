import SwiftUI

struct StepEditInfo: Identifiable {
    let id = UUID()
    let trackIdx: Int
    let stepIdx: Int
}

struct SequencerView: View {
    @Environment(SynthEngine.self) var engine
    @State private var vm: SequencerViewModel?
    @State private var editingStepInfo: StepEditInfo? = nil
    @State private var editingVoiceTrackIndex: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            if let vm {
                TransportBar(vm: vm)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 1) {
                        ForEach(vm.activePattern.tracks.indices, id: \.self) { ti in
                            trackRow(vm: vm, trackIndex: ti)
                            Divider().background(Color.synthBorder)
                        }
                    }
                }
            }
        }
        .background(Color.synthBg)
        .onAppear {
            let seqVm = SequencerViewModel()
            seqVm.synthEngine = engine
            seqVm.midiEngine = engine.midiEngineInstance
            vm = seqVm
        }
        .sheet(item: $editingStepInfo) { info in
            if let vm {
                StepEditSheet(step: Binding(
                    get: { vm.activePattern.tracks[info.trackIdx].steps[info.stepIdx] },
                    set: { vm.activePattern.tracks[info.trackIdx].steps[info.stepIdx] = $0 }
                ))
            }
        }
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
    }

    @ViewBuilder
    private func trackRow(vm: SequencerViewModel, trackIndex: Int) -> some View {
        HStack(spacing: 0) {
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

            Divider().frame(height: 36).background(Color.synthBorder)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(vm.activePattern.tracks[trackIndex].steps.indices, id: \.self) { si in
                        StepCellView(
                            step: Binding(
                                get: { vm.activePattern.tracks[trackIndex].steps[si] },
                                set: { vm.activePattern.tracks[trackIndex].steps[si] = $0 }
                            ),
                            isCurrent: vm.isPlaying && si == vm.currentStep
                        ) {
                            editingStepInfo = StepEditInfo(trackIdx: trackIndex, stepIdx: si)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(height: 36)
    }

    private func voiceBadge(vm: SequencerViewModel, trackIndex: Int) -> some View {
        let track = vm.activePattern.tracks[trackIndex]
        let (label, color): (String, Color) = {
            switch track.voiceType {
            case .internalVoice:
                let idx = vm.activePattern.internalVoiceIndex(for: track.id) ?? 0
                return ("I\(idx + 1)", .synthGreen)
            case .midiOut(let ch):
                return ("M\(ch)", .synthBlue)
            }
        }()
        return Button {
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

    private func toggleButton(_ label: String, isOn: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.synthLabel)
                .foregroundStyle(isOn ? Color.synthBg : activeColor)
                .frame(width: 16, height: 14)
                .background(isOn ? activeColor : Color.clear)
        }
    }
}

private struct IdentifiableInt: Identifiable {
    let value: Int
    var id: Int { value }
}

struct StepEditSheet: View {
    @Binding var step: Step
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("STEP EDIT").font(.synthMonoLg).foregroundStyle(Color.synthGreen)
                Spacer()
                Button("DONE") { dismiss() }.font(.synthMono).foregroundStyle(Color.synthAmber)
            }
            Stepper("NOTE: \(step.note)", value: $step.note, in: 0...127)
                .font(.synthMono).foregroundStyle(Color.synthText)
            Stepper("VEL: \(step.velocity)", value: $step.velocity, in: 0...127)
                .font(.synthMono).foregroundStyle(Color.synthText)
            VStack(alignment: .leading, spacing: 4) {
                Text("PROB: \(Int(step.probability * 100))%").font(.synthLabel).foregroundStyle(Color.synthText)
                Slider(value: $step.probability, in: 0...1).tint(Color.synthGreen)
            }
            Toggle("ACCENT", isOn: $step.isAccent)
                .font(.synthMono).foregroundStyle(Color.synthText).tint(Color.synthAmber)
        }
        .padding()
        .background(Color.synthPanel)
        .presentationDetents([.height(260)])
    }
}
