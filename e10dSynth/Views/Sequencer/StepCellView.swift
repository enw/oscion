import SwiftUI

struct StepCellView: View {
    @Binding var step: Step
    let isCurrent: Bool
    var onLongPress: (() -> Void)?

    var body: some View {
        Rectangle()
            .fill(cellColor)
            .overlay(Rectangle().stroke(
                isCurrent ? Color.synthAmber : Color.synthBorder,
                lineWidth: isCurrent ? 2 : 0.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                step.isOn.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .onLongPressGesture { onLongPress?() }
    }

    private var cellColor: Color {
        if !step.isOn { return Color.synthDimGreen.opacity(0.5) }
        return step.isAccent ? Color.synthAmber : Color.synthGreen
    }
}
