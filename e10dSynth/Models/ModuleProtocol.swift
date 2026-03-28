import Foundation
import AudioKit

enum ModuleType: String, Codable, CaseIterable {
    case vco, vcf, vca, env, lfo, seq, midiIn, midiOut, out
}

protocol SynthModule: AnyObject, Identifiable {
    var id: String { get }
    var moduleType: ModuleType { get }
    var name: String { get }
    var inputs: [Jack] { get }
    var outputs: [Jack] { get }
    var outputNode: (any Node)? { get }
}
