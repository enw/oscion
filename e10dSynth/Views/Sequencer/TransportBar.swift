import SwiftUI

struct TransportBar: View {
    let vm: SequencerViewModel

    var body: some View {
        HStack(spacing: 0) {
            // Play/stop
            Button {
                vm.isPlaying ? vm.stop() : vm.play()
            } label: {
                Image(systemName: vm.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(vm.isPlaying ? Color.synthAmber : Color.synthGreen)
                    .frame(width: 52, height: 52)
            }

            divider

            // BPM
            HStack(spacing: 2) {
                Text("BPM").font(.synthLabel).foregroundStyle(Color.synthText)
                Button { vm.clock.bpm = max(20, vm.clock.bpm - 1) } label: {
                    Text("−").font(.synthMono).foregroundStyle(Color.synthGreen).frame(width: 20, height: 32)
                }
                Text(String(format: "%.0f", vm.clock.bpm))
                    .font(.synthMonoLg).foregroundStyle(Color.synthGreen)
                    .monospacedDigit().frame(width: 38)
                Button { vm.clock.bpm = min(250, vm.clock.bpm + 1) } label: {
                    Text("+").font(.synthMono).foregroundStyle(Color.synthGreen).frame(width: 20, height: 32)
                }
            }
            .padding(.horizontal, 8)

            divider

            // Swing
            HStack(spacing: 6) {
                Text("SW").font(.synthLabel).foregroundStyle(Color.synthText)
                Slider(value: Binding(get: { vm.clock.swing }, set: { vm.clock.swing = $0 }), in: 0...100)
                    .tint(Color.synthAmber)
                    .frame(width: 70)
            }
            .padding(.horizontal, 8)

            divider

            // Pattern grid — horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(0..<16, id: \.self) { i in
                        Button { vm.activePatternIndex = i } label: {
                            Text(vm.patterns[i].name)
                                .font(.synthLabel)
                                .foregroundStyle(vm.activePatternIndex == i ? Color.synthBg : Color.synthText)
                                .frame(width: 28, height: 20)
                                .background(vm.activePatternIndex == i ? Color.synthGreen : Color.synthDimGreen)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: 52)
        .background(Color.synthPanel)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.synthBorder), alignment: .bottom)
    }

    private var divider: some View {
        Rectangle().fill(Color.synthBorder).frame(width: 1, height: 32)
    }
}
