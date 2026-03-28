import XCTest
@testable import e10dSynth

final class PresetManagerTests: XCTestCase {

    func testSaveAndLoadPreset() throws {
        let manager = PresetManager.shared
        let vm = SequencerViewModel()
        vm.activePattern.tracks[0].toggleStep(at: 0)
        vm.activePattern.tracks[0].toggleStep(at: 7)
        vm.clock.bpm = 140
        vm.clock.swing = 25

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_preset_\(UUID().uuidString).e10d")
        try manager.save(sequencer: vm, to: url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let loaded = try manager.load(from: url)
        XCTAssertTrue(loaded.patterns[0].tracks[0].steps[0].isOn)
        XCTAssertTrue(loaded.patterns[0].tracks[0].steps[7].isOn)
        XCTAssertFalse(loaded.patterns[0].tracks[0].steps[1].isOn)
        XCTAssertEqual(loaded.clock.bpm, 140, accuracy: 0.01)
        XCTAssertEqual(loaded.clock.swing, 25, accuracy: 0.01)

        try FileManager.default.removeItem(at: url)
    }

    func testListPresetsEmpty() {
        _ = PresetManager.shared.listPresets()
    }
}
