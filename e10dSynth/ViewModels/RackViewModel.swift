import Foundation
import SwiftUI

/// Identifies a specific jack on a specific module (used during patch drag)
struct JackRef: Equatable {
    let moduleId: String
    let jackId: String
    let signalType: SignalType
    let direction: JackDirection
}

@Observable
final class RackViewModel {

    // MARK: - Layout
    /// Module IDs in display order
    var moduleOrder: [String] = []
    /// Module card positions on the canvas (center point)
    var modulePositions: [String: CGPoint] = [:]

    // MARK: - Patching interaction
    /// Jack currently being dragged from (nil if not dragging)
    var draggingFromJack: JackRef? = nil
    /// Current drag endpoint (follows finger)
    var draggingPoint: CGPoint = .zero
    /// Jack the drag is hovering over (for highlight)
    var hoveredJack: JackRef? = nil

    // MARK: - Jack screen positions
    /// Populated by module card views via GeometryReader
    /// Key format: "\(moduleId).\(jackId)"
    var jackPositions: [String: CGPoint] = [:]

    // MARK: - Dependencies
    let graph: ModularGraph
    let engine: SynthEngine

    init(engine: SynthEngine) {
        self.engine = engine
        self.graph = engine.graph
        setupDefaultPositions()
    }

    // MARK: - Jack key helper
    func jackKey(_ moduleId: String, _ jackId: String) -> String {
        "\(moduleId).\(jackId)"
    }

    func registerJackPosition(moduleId: String, jackId: String, position: CGPoint) {
        jackPositions[jackKey(moduleId, jackId)] = position
    }

    // MARK: - Drag-to-patch
    func startDrag(from ref: JackRef, at point: CGPoint) {
        draggingFromJack = ref
        draggingPoint = point
    }

    func updateDrag(to point: CGPoint) {
        draggingPoint = point
    }

    func endDrag() {
        defer {
            draggingFromJack = nil
            hoveredJack = nil
            draggingPoint = .zero
        }
        guard let src = draggingFromJack, let dst = hoveredJack else { return }
        _ = graph.connect(
            fromModule: src.moduleId, fromJack: src.jackId,
            toModule: dst.moduleId, toJack: dst.jackId
        )
        engine.rebuildAudioChain()
    }

    func removePatch(_ id: UUID) {
        graph.disconnect(id)
        engine.rebuildAudioChain()
    }

    // MARK: - Module management
    func moveModule(_ moduleId: String, to position: CGPoint) {
        modulePositions[moduleId] = position
        graph.modulePositions[moduleId] = position
    }

    func addModule(_ type: ModuleType) {
        let module = engine.createModule(type: type)
        let x = CGFloat.random(in: 100...500)
        let y = CGFloat.random(in: 150...700)
        let pos = CGPoint(x: x, y: y)
        modulePositions[module.id] = pos
        graph.modulePositions[module.id] = pos
        moduleOrder.append(module.id)
    }

    // MARK: - Private
    private func setupDefaultPositions() {
        // Lay out existing modules left-to-right
        var x: CGFloat = 120
        // Sort for deterministic ordering
        let sorted = graph.modules.keys.sorted()
        for id in sorted {
            modulePositions[id] = CGPoint(x: x, y: 300)
            graph.modulePositions[id] = CGPoint(x: x, y: 300)
            moduleOrder.append(id)
            x += 220
        }
    }
}
