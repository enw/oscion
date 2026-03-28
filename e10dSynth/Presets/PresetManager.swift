import Foundation

struct SynthPreset: Codable {
    let patterns: [Pattern]
    let activePatternIndex: Int
    let bpm: Double
    let swing: Double
}

final class PresetManager {
    static let shared = PresetManager()
    private init() {}

    private var presetDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func save(sequencer: SequencerViewModel, to url: URL) throws {
        let preset = SynthPreset(
            patterns: sequencer.patterns,
            activePatternIndex: sequencer.activePatternIndex,
            bpm: sequencer.clock.bpm,
            swing: sequencer.clock.swing
        )
        let data = try JSONEncoder().encode(preset)
        try data.write(to: url, options: .atomic)
    }

    func load(from url: URL) throws -> SequencerViewModel {
        let data = try Data(contentsOf: url)
        let preset = try JSONDecoder().decode(SynthPreset.self, from: data)
        let vm = SequencerViewModel()
        vm.patterns = preset.patterns
        vm.activePatternIndex = preset.activePatternIndex
        vm.clock.bpm = preset.bpm
        vm.clock.swing = preset.swing
        return vm
    }

    func listPresets() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: presetDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "e10d" }) ?? []
    }
}
