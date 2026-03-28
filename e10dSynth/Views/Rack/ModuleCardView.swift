import SwiftUI

struct ModuleCardView: View {
    let module: any SynthModule
    let vm: RackViewModel
    @State private var position: CGPoint

    init(module: any SynthModule, vm: RackViewModel) {
        self.module = module
        self.vm = vm
        _position = State(initialValue: vm.modulePositions[module.id] ?? CGPoint(x: 200, y: 300))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(module.name)
                .font(.synthMonoSm)
                .foregroundStyle(Color.synthGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(Color.synthDimGreen)

            Divider().background(Color.synthBorder)

            HStack(alignment: .top, spacing: 0) {
                // Input jacks (left)
                VStack(spacing: 10) {
                    ForEach(module.inputs) { jack in
                        JackView(jack: jack, moduleId: module.id) { ref, pt in
                            vm.startDrag(from: ref, at: pt)
                        }
                    }
                }
                .frame(width: 52)
                .padding(.vertical, 8)

                Divider().background(Color.synthBorder)

                // Module controls (center)
                moduleControls
                    .frame(maxWidth: .infinity)
                    .padding(8)

                Divider().background(Color.synthBorder)

                // Output jacks (right)
                VStack(spacing: 10) {
                    ForEach(module.outputs) { jack in
                        JackView(jack: jack, moduleId: module.id) { ref, pt in
                            vm.startDrag(from: ref, at: pt)
                        }
                    }
                }
                .frame(width: 52)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 200)
        .background(Color.synthPanel)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.synthBorder, lineWidth: 1))
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { g in position = g.location }
                .onEnded   { g in vm.moveModule(module.id, to: g.location) }
        )
    }

    @ViewBuilder
    private var moduleControls: some View {
        switch module.moduleType {
        case .vco:
            if let m = module as? VCOModule { VCOControlsView(module: m) }
        case .vcf:
            if let m = module as? VCFModule { VCFControlsView(module: m) }
        case .vca:
            if let m = module as? VCAModule { VCAControlsView(module: m) }
        case .env:
            if let m = module as? ENVModule { ENVControlsView(module: m) }
        case .lfo:
            if let m = module as? LFOModule { LFOControlsView(module: m) }
        default:
            Text(module.name)
                .font(.synthMono)
                .foregroundStyle(Color.synthText)
        }
    }
}
