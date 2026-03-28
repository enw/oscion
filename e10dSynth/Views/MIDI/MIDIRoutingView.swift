import SwiftUI

struct MIDIRoutingView: View {
    @Environment(SynthEngine.self) var engine

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("PORTS")
                portsSection

                Divider().background(Color.synthBorder)

                sectionHeader("CHANNELS")
                channelsSection

                Divider().background(Color.synthBorder)

                sectionHeader("MIDI LEARN")
                learnSection
            }
        }
        .background(Color.synthBg)
        .navigationBarHidden(true)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.synthLabel)
            .foregroundStyle(Color.synthText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.synthDimGreen.opacity(0.5))
    }

    private var portsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("VIRTUAL PORT").font(.synthMono).foregroundStyle(Color.synthText)
                Spacer()
                Circle()
                    .fill(engine.midiEngineInstance.isConnected ? Color.synthGreen : Color.synthBorder)
                    .frame(width: 8, height: 8)
                Text(engine.midiEngineInstance.isConnected ? "ACTIVE" : "OFF")
                    .font(.synthLabel)
                    .foregroundStyle(engine.midiEngineInstance.isConnected ? Color.synthGreen : Color.synthText)
            }
            .padding()
        }
    }

    private var channelsSection: some View {
        VStack(spacing: 0) {
            channelRow(label: "RECEIVE CH",
                       value: Binding(
                        get: { engine.midiEngineInstance.receiveChannel },
                        set: { engine.midiEngineInstance.receiveChannel = $0 }))
            Divider().background(Color.synthBorder)
            channelRow(label: "SEND CH",
                       value: Binding(
                        get: { engine.midiEngineInstance.sendChannel },
                        set: { engine.midiEngineInstance.sendChannel = $0 }))
        }
    }

    private func channelRow(label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label).font(.synthMono).foregroundStyle(Color.synthText)
            Spacer()
            Stepper("CH \(value.wrappedValue)", value: value, in: 1...16)
                .font(.synthMono).foregroundStyle(Color.synthGreen)
        }
        .padding()
    }

    private var learnSection: some View {
        Text("Long-press any knob to enter MIDI Learn.\nWiggle a CC to map.")
            .font(.synthMonoSm)
            .foregroundStyle(Color.synthText)
            .padding()
    }
}
