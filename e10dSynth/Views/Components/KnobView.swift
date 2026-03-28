import SwiftUI

struct KnobView: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    var unit: String = ""
    var size: CGFloat = 48

    @State private var lastDragY: CGFloat = 0
    @State private var isDragging = false

    private var normalizedValue: Double {
        Double((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    private var displayValue: String {
        let absVal = abs(value)
        if absVal < 10  { return String(format: "%.2f%@", value, unit) }
        if absVal < 100 { return String(format: "%.1f%@", value, unit) }
        return String(format: "%.0f%@", value, unit)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.synthPanel)
                    .overlay(Circle().stroke(Color.synthBorder, lineWidth: 1))

                // Value arc: from 135° to 135° + 270° * normalizedValue
                Circle()
                    .trim(from: 0, to: normalizedValue * 0.75)
                    .stroke(
                        isDragging ? Color.synthAmber : Color.synthGreen,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))

                // Tick mark pointer
                let angle = Angle.degrees(-225 + normalizedValue * 270)
                Capsule()
                    .fill(Color.synthGreen)
                    .frame(width: 2, height: size * 0.3)
                    .offset(y: -(size * 0.22))
                    .rotationEffect(angle)
            }
            .frame(width: size, height: size)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            lastDragY = gesture.startLocation.y
                            isDragging = true
                        }
                        let delta = Float(lastDragY - gesture.location.y) / 150.0
                        lastDragY = gesture.location.y
                        let span = range.upperBound - range.lowerBound
                        value = min(range.upperBound, max(range.lowerBound, value + delta * span))
                    }
                    .onEnded { _ in isDragging = false }
            )

            Text(label)
                .font(.synthLabel)
                .foregroundStyle(Color.synthText)

            Text(displayValue)
                .font(.synthMonoSm)
                .foregroundStyle(isDragging ? Color.synthAmber : Color.synthGreen)
                .monospacedDigit()
                .lineLimit(1)
        }
    }
}
