import SwiftUI

struct PatchCableOverlay: View {
    let patches: [Patch]
    let jackPositions: [String: CGPoint]
    let draggingFrom: JackRef?
    let draggingPoint: CGPoint
    let onRemovePatch: (UUID) -> Void

    var body: some View {
        Canvas { ctx, _ in
            // Draw committed cables
            for patch in patches {
                let srcKey = "\(patch.fromModuleId).\(patch.fromJackId)"
                let dstKey = "\(patch.toModuleId).\(patch.toJackId)"
                guard let src = jackPositions[srcKey],
                      let dst = jackPositions[dstKey] else { continue }
                drawCable(ctx: ctx, from: src, to: dst,
                          color: cableColor(fromJackId: patch.fromJackId),
                          dashed: false)
            }

            // Draw in-progress drag cable
            if let from = draggingFrom,
               let srcPos = jackPositions["\(from.moduleId).\(from.jackId)"] {
                drawCable(ctx: ctx, from: srcPos, to: draggingPoint,
                          color: Color.signalColor(from.signalType).opacity(0.5),
                          dashed: true)
            }
        }
        .onTapGesture { point in
            if let patch = nearestPatch(to: point) {
                onRemovePatch(patch.id)
            }
        }
        .allowsHitTesting(draggingFrom == nil)
    }

    private func drawCable(ctx: GraphicsContext, from: CGPoint, to: CGPoint,
                            color: Color, dashed: Bool) {
        let cp1 = CGPoint(x: from.x + 80, y: from.y)
        let cp2 = CGPoint(x: to.x - 80, y: to.y)
        var path = Path()
        path.move(to: from)
        path.addCurve(to: to, control1: cp1, control2: cp2)
        let shading = GraphicsContext.Shading.color(color)
        if dashed {
            ctx.stroke(path, with: shading,
                       style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
        } else {
            ctx.stroke(path, with: shading,
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }

    private func cableColor(fromJackId: String) -> Color {
        if fromJackId.contains("audio") { return Color.synthGreen }
        if fromJackId.contains("cv")    { return Color.synthAmber }
        return Color.synthRed
    }

    private func nearestPatch(to point: CGPoint) -> Patch? {
        for patch in patches {
            let srcKey = "\(patch.fromModuleId).\(patch.fromJackId)"
            let dstKey = "\(patch.toModuleId).\(patch.toJackId)"
            guard let src = jackPositions[srcKey],
                  let dst = jackPositions[dstKey] else { continue }
            let cp1 = CGPoint(x: src.x + 80, y: src.y)
            let cp2 = CGPoint(x: dst.x - 80, y: dst.y)
            for ti in 0...20 {
                let t = Double(ti) / 20.0
                let pt = cubicBezier(t: t, p0: src, p1: cp1, p2: cp2, p3: dst)
                if hypot(pt.x - point.x, pt.y - point.y) < 14 { return patch }
            }
        }
        return nil
    }

    private func cubicBezier(t: Double, p0: CGPoint, p1: CGPoint,
                              p2: CGPoint, p3: CGPoint) -> CGPoint {
        let mt = 1 - t
        let x = mt*mt*mt*p0.x + 3*mt*mt*t*p1.x + 3*mt*t*t*p2.x + t*t*t*p3.x
        let y = mt*mt*mt*p0.y + 3*mt*mt*t*p1.y + 3*mt*t*t*p2.y + t*t*t*p3.y
        return CGPoint(x: x, y: y)
    }
}
