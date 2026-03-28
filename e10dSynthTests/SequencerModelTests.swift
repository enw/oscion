import XCTest
@testable import e10dSynth

final class SequencerModelTests: XCTestCase {

    func testStepDefaultsOff() {
        XCTAssertFalse(Step().isOn)
    }

    func testStepDefaultVelocity() {
        XCTAssertEqual(Step().velocity, 100)
    }

    func testTrackDefaultStepCount() {
        XCTAssertEqual(Track().steps.count, 16)
    }

    func testTrackToggleStepOn() {
        var track = Track()
        track.toggleStep(at: 0)
        XCTAssertTrue(track.steps[0].isOn)
    }

    func testTrackToggleStepOffAfterOn() {
        var track = Track()
        track.toggleStep(at: 0)
        track.toggleStep(at: 0)
        XCTAssertFalse(track.steps[0].isOn)
    }

    func testTrackToggleOutOfBoundsNocrash() {
        var track = Track()
        track.toggleStep(at: 99)  // must not crash
    }

    func testTrackSetAccent() {
        var track = Track()
        track.toggleStep(at: 3)
        track.setAccent(at: 3, true)
        XCTAssertTrue(track.steps[3].isAccent)
    }

    func testTrackResizeGrows() {
        var track = Track()
        track.stepCount = 32
        XCTAssertEqual(track.steps.count, 32)
    }

    func testTrackResizeShrinks() {
        var track = Track()
        track.stepCount = 8
        XCTAssertEqual(track.steps.count, 8)
    }

    func testPatternHasEightTracks() {
        XCTAssertEqual(Pattern().tracks.count, 8)
    }

    func testPatternDefaultName() {
        XCTAssertEqual(Pattern().name, "A1")
    }

    func testStepCodableRoundTrip() throws {
        var step = Step()
        step.isOn = true
        step.note = 60
        step.velocity = 127
        let data = try JSONEncoder().encode(step)
        let decoded = try JSONDecoder().decode(Step.self, from: data)
        XCTAssertEqual(decoded.note, 60)
        XCTAssertEqual(decoded.velocity, 127)
        XCTAssertTrue(decoded.isOn)
    }

    func testTrackCodableRoundTrip() throws {
        var track = Track()
        track.toggleStep(at: 5)
        let data = try JSONEncoder().encode(track)
        let decoded = try JSONDecoder().decode(Track.self, from: data)
        XCTAssertTrue(decoded.steps[5].isOn)
    }

    func testTrackVoiceTypeDefaultIsInternal() {
        let track = Track()
        if case .internalVoice = track.voiceType { } else {
            XCTFail("Expected internalVoice default")
        }
    }

    func testTrackVoiceTypeCodableRoundTrip() throws {
        var track = Track()
        track.voiceType = .midiOut(channel: 7)
        let data = try JSONEncoder().encode(track)
        let decoded = try JSONDecoder().decode(Track.self, from: data)
        if case .midiOut(let ch) = decoded.voiceType {
            XCTAssertEqual(ch, 7)
        } else {
            XCTFail("Expected midiOut after round-trip")
        }
    }

    func testVoiceSettingsDefaults() {
        let s = TrackVoiceSettings()
        XCTAssertEqual(s.waveform, .sawtooth)
        XCTAssertEqual(s.octave, 4)
        XCTAssertEqual(s.cutoff, 1000, accuracy: 0.01)
    }

    func testInternalVoiceCountHelper() {
        var pattern = Pattern()
        // default: all 8 tracks are .internalVoice
        XCTAssertEqual(pattern.internalVoiceCount, 8)
        pattern.tracks[0].voiceType = .midiOut(channel: 1)
        XCTAssertEqual(pattern.internalVoiceCount, 7)
    }

    func testInternalVoiceIndexForTrack() {
        var pattern = Pattern()
        pattern.tracks[1].voiceType = .midiOut(channel: 2)
        // track[0] = internal → index 0
        // track[1] = midi → no index
        // track[2] = internal → index 1
        XCTAssertEqual(pattern.internalVoiceIndex(for: pattern.tracks[0].id), 0)
        XCTAssertNil(pattern.internalVoiceIndex(for: pattern.tracks[1].id))
        XCTAssertEqual(pattern.internalVoiceIndex(for: pattern.tracks[2].id), 1)
    }
}
