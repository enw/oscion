import SwiftUI

struct JackView: View {
    let jack: Jack
    let moduleId: String
    var isActive: Bool = false
    var onDragStart: ((JackRef, CGPoint) -> Void)?

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.signalColor(jack.signalType) : Color.synthPanel)
                .overlay(Circle().stroke(Color.signalColor(jack.signalType), lineWidth: 1.5))
                .frame(width: 18, height: 18)
        }
        .overlay(
            Text(jack.name)
                .font(.synthLabel)
                .foregroundStyle(Color.synthText)
                .fixedSize()
                .offset(x: jack.direction == .input ? -38 : 38),
            alignment: .center
        )
        .contentShape(Rectangle().size(CGSize(width: 44, height: 44)))
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    let frame = geo.frame(in: .global)
                    let center = CGPoint(x: frame.midX, y: frame.midY)
                    let ref = JackRef(moduleId: moduleId, jackId: jack.id,
                                      signalType: jack.signalType, direction: jack.direction)
                    onDragStart?(ref, center)
                }
            }
        )
        .gesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged { g in
                    if g.translation == CGSize.zero {
                        let ref = JackRef(moduleId: moduleId, jackId: jack.id,
                                          signalType: jack.signalType, direction: jack.direction)
                        onDragStart?(ref, g.startLocation)
                    }
                }
        )
    }
}
