import SwiftUI

struct TransportBar: View {
    let vm: SequencerViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Row 1: Play + BPM + Swing
            HStack(spacing: 12) {
                Button {
                    vm.isPlaying ? vm.stop() : vm.play()
                } label: {
                    Image(systemName: vm.isPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(vm.isPlaying ? Color.synthAmber : Color.synthGreen)
                        .frame(width: 48, height: 36)
                        .background(Color.synthDimGreen.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Divider().frame(height: 28).background(Color.synthBorder)

                // BPM
                HStack(spacing: 4) {
                    Text("BPM").font(.synthLabel).foregroundStyle(Color.synthText)
                    Button { vm.clock.bpm = max(20, vm.clock.bpm - 1) } label: {
                        Text("−").font(.synthMono).foregroundStyle(Color.synthGreen).frame(width: 22, height: 28)
                    }
                    Text(String(format: "%.0f", vm.clock.bpm))
                        .font(.synthMonoLg).foregroundStyle(Color.synthGreen)
                        .monospacedDigit().frame(minWidth: 36)
                    Button { vm.clock.bpm = min(250, vm.clock.bpm + 1) } label: {
                        Text("+").font(.synthMono).foregroundStyle(Color.synthGreen).frame(width: 22, height: 28)
                    }
                }

                Divider().frame(height: 28).background(Color.synthBorder)

                // Swing
                HStack(spacing: 6) {
                    Text("SW").font(.synthLabel).foregroundStyle(Color.synthText)
                    Slider(value: Binding(get: { vm.clock.swing }, set: { vm.clock.swing = $0 }), in: 0...100)
                        .tint(Color.synthAmber)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().background(Color.synthBorder)

            // Row 2: Pattern grid
            PatternGrid(vm: vm)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .background(Color.synthPanel)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.synthBorder), alignment: .bottom)
    }
}

struct PatternGrid: View {
    let vm: SequencerViewModel
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 3) {
                ForEach(0..<16, id: \.self) { i in
                    Button { vm.activePatternIndex = i } label: {
                        Text(vm.patterns[i].name)
                            .font(.synthLabel)
                            .foregroundStyle(vm.activePatternIndex == i ? Color.synthBg : Color.synthText)
                            .frame(width: 32, height: 22)
                            .background(vm.activePatternIndex == i ? Color.synthGreen : Color.synthDimGreen)
                    }
                }
            }
        }
    }
}
