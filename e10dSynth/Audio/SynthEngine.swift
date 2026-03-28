import Foundation
import SwiftUI

/// Central engine singleton. Owns AudioKit engine + modular graph.
/// Audio modules (VCO/VCF/etc.) are added in Tasks 6–9.
@Observable
final class SynthEngine {
    static let shared = SynthEngine()

    let graph = ModularGraph()
    let midiEngineInstance = MIDIEngine()
    private(set) var isRunning = false

    private init() {}

    func start() {
        guard !isRunning else { return }
        isRunning = true
        // AudioKit engine start added in Task 6 once modules exist
    }

    func stop() {
        isRunning = false
        // AudioKit engine stop added in Task 6
    }

    /// Called when the patch graph changes — rebuilds AudioKit node connections.
    /// Full implementation added in Task 6.
    func rebuildAudioChain() {
        // stub — implemented after audio modules exist
    }

    /// Create and register a module by type. Audio wiring added per task.
    func createModule(type: ModuleType) -> any SynthModule {
        // Returns stub modules until real implementations exist (Tasks 6–9)
        fatalError("createModule not yet implemented — added in Tasks 6–9")
    }

    /// Trigger note on all VCO/ENV modules in graph.
    func noteOn(note: Int, velocity: Int) {
        // implemented in Task 6
    }

    /// Release note on all VCO/ENV modules in graph.
    func noteOff(note: Int) {
        // implemented in Task 6
    }
}
