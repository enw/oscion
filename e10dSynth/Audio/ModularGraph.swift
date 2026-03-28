import Foundation
import SwiftUI

@Observable
final class ModularGraph {
    private(set) var modules: [String: any SynthModule] = [:]
    private(set) var patches: [Patch] = []
    var modulePositions: [String: CGPoint] = [:]

    func add(_ module: some SynthModule) {
        modules[module.id] = module
    }

    func remove(_ moduleId: String) {
        modules.removeValue(forKey: moduleId)
        patches.removeAll { $0.fromModuleId == moduleId || $0.toModuleId == moduleId }
    }

    @discardableResult
    func connect(fromModule: String, fromJack: String, toModule: String, toJack: String) -> Bool {
        guard
            let src = modules[fromModule],
            let dst = modules[toModule],
            let srcJack = src.outputs.first(where: { $0.id == fromJack }),
            let dstJack = dst.inputs.first(where: { $0.id == toJack }),
            srcJack.canConnect(to: dstJack)
        else { return false }

        // Prevent duplicate patches
        let exists = patches.contains {
            $0.fromModuleId == fromModule && $0.fromJackId == fromJack &&
            $0.toModuleId == toModule && $0.toJackId == toJack
        }
        guard !exists else { return true }

        let patch = Patch(fromModuleId: fromModule, fromJackId: fromJack,
                          toModuleId: toModule, toJackId: toJack)
        patches.append(patch)
        return true
    }

    func disconnect(_ patchId: UUID) {
        patches.removeAll { $0.id == patchId }
    }
}

