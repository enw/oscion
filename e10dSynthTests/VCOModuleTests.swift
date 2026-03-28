import XCTest
@testable import e10dSynth

final class VCOModuleTests: XCTestCase {

    func testVCOHasCorrectOutputJack() {
        let vco = VCOModule()
        XCTAssertTrue(vco.outputs.contains { $0.id == "audioOut" && $0.signalType == .audio })
    }

    func testVCOHasCorrectInputJacks() {
        let vco = VCOModule()
        XCTAssertTrue(vco.inputs.contains { $0.id == "cvPitch" && $0.signalType == .cv })
        XCTAssertTrue(vco.inputs.contains { $0.id == "gateIn" && $0.signalType == .gate })
    }

    func testVCOWaveformChange() {
        let vco = VCOModule()
        vco.waveform = .sawtooth
        XCTAssertEqual(vco.waveform, .sawtooth)
        vco.waveform = .triangle
        XCTAssertEqual(vco.waveform, .triangle)
    }

    func testVCOTuneClampedToRange() {
        let vco = VCOModule()
        vco.tune = 30  // above max 24
        XCTAssertLessThanOrEqual(vco.tune, 24)
        vco.tune = -30 // below min -24
        XCTAssertGreaterThanOrEqual(vco.tune, -24)
    }

    func testVCOOctaveClampedToRange() {
        let vco = VCOModule()
        vco.octave = 10 // above max 8
        XCTAssertLessThanOrEqual(vco.octave, 8)
        vco.octave = -1 // below min 0
        XCTAssertGreaterThanOrEqual(vco.octave, 0)
    }

    func testVCOFrequencyA440() {
        let vco = VCOModule()
        vco.noteOn(69, velocity: 100)  // MIDI 69 = A4 = 440 Hz
        XCTAssertEqual(vco.frequency, 440.0, accuracy: 0.01)
    }

    func testVCOFrequencyOctaveUp() {
        let vco = VCOModule()
        vco.noteOn(81, velocity: 100)  // MIDI 81 = A5 = 880 Hz
        XCTAssertEqual(vco.frequency, 880.0, accuracy: 0.1)
    }

    func testNoteOnSetsAmplitude() {
        let vco = VCOModule()
        vco.noteOn(60, velocity: 127)
        XCTAssertGreaterThan(vco.amplitude, 0)
    }

    func testNoteOffZerosAmplitude() {
        let vco = VCOModule()
        vco.noteOn(60, velocity: 100)
        vco.noteOff()
        XCTAssertEqual(vco.amplitude, 0)
    }

    func testVCOModuleType() {
        let vco = VCOModule()
        XCTAssertEqual(vco.moduleType, .vco)
    }
}
