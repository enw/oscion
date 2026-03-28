import SwiftUI

struct RackView: View {
    @Environment(SynthEngine.self) var engine
    @State private var vm: RackViewModel?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showAddModule = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                GridBackground()

                if let vm {
                    ZStack {
                        PatchCableOverlay(
                            patches: vm.graph.patches,
                            jackPositions: vm.jackPositions,
                            draggingFrom: vm.draggingFromJack,
                            draggingPoint: vm.draggingPoint,
                            onRemovePatch: vm.removePatch
                        )
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
                                .onChanged { val in
                                    scale = max(0.3, min(2.5, val))
                                },
                            DragGesture()
                                .onChanged { g in
                                    if vm.draggingFromJack != nil {
                                        vm.updateDrag(to: g.location)
                                    } else {
                                        offset = g.translation
                                    }
                                }
                                .onEnded { _ in
                                    if vm.draggingFromJack != nil {
                                        vm.endDrag()
                                    }
                                }
                        )
                    )
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { showAddModule = true } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundStyle(Color.synthGreen)
                                .frame(width: 48, height: 48)
                                .background(Color.synthPanel)
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.synthBorder))
                        }
                        .padding()
                    }
                }
            }
            .onAppear {
                vm = RackViewModel(engine: engine)
            }
        }
        .background(Color.synthBg)
        .sheet(isPresented: $showAddModule) {
            AddModuleSheet { type in
                vm?.addModule(type)
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
            while x <= size.width {
                var y: CGFloat = 0
                while y <= size.height {
                    path.addEllipse(in: CGRect(x: x - 0.8, y: y - 0.8, width: 1.6, height: 1.6))
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
