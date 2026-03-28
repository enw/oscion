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
}
