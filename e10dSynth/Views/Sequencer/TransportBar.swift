import SwiftUI

struct TransportBar: View {
    let vm: SequencerViewModel

    var body: some View {
        HStack(spacing: 16) {
            Button {
                vm.isPlaying ? vm.stop() : vm.play()
            } label: {
                Image(systemName: vm.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title3)
                    .foregroundStyle(vm.isPlaying ? Color.synthAmber : Color.synthGreen)
                    .frame(width: 44, height: 44)
            }

            Divider().frame(height: 28).background(Color.synthBorder)

            VStack(spacing: 2) {
                Text("BPM").font(.synthLabel).foregroundStyle(Color.synthText)
                HStack(spacing: 4) {
                    Button { vm.clock.bpm = max(20, vm.clock.bpm - 1) } label: {
                        Text("−").font(.synthMono).foregroundStyle(Color.synthGreen).frame(width: 24, height: 24)
                    }
                    Text(String(format: "%.0f", vm.clock.bpm))
                        .font(.synthMonoLg).foregroundStyle(Color.synthGreen)
                        .monospacedDigit().frame(width: 44)
                    Button { vm.clock.bpm = min(250, vm.clock.bpm + 1) } label: {
                        Text("+").font(.synthMono).foregroundStyle(Color.synthGreen).frame(width: 24, height: 24)
                    }
                }
            }

            Divider().frame(height: 28).background(Color.synthBorder)

            VStack(spacing: 2) {
                Text("SWING").font(.synthLabel).foregroundStyle(Color.synthText)
                Slider(value: Binding(get: { vm.clock.swing }, set: { vm.clock.swing = $0 }), in: 0...100)
                    .tint(Color.synthAmber).frame(width: 80)
            }

            Spacer()

            PatternGrid(vm: vm)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.synthPanel)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.synthBorder), alignment: .bottom)
    }
}

struct PatternGrid: View {
    let vm: SequencerViewModel
    var body: some View {
        LazyVGrid(columns: Array(repeating: .init(.fixed(26)), count: 4), spacing: 3) {
            ForEach(0..<16, id: \.self) { i in
                Button { vm.activePatternIndex = i } label: {
                    Text(vm.patterns[i].name)
                        .font(.synthLabel)
                        .foregroundStyle(vm.activePatternIndex == i ? Color.synthBg : Color.synthText)
                        .frame(width: 24, height: 18)
                        .background(vm.activePatternIndex == i ? Color.synthGreen : Color.synthDimGreen)
                }
            }
        }
    }
}
