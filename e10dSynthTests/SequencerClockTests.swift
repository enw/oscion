import XCTest
@testable import e10dSynth

final class SequencerClockTests: XCTestCase {

    func testBPMClampedHigh() {
        let clock = SequencerClock()
        clock.bpm = 300
        XCTAssertLessThanOrEqual(clock.bpm, 250)
    }

    func testBPMClampedLow() {
        let clock = SequencerClock()
        clock.bpm = 5
        XCTAssertGreaterThanOrEqual(clock.bpm, 20)
    }

    func testStepIntervalAt120BPM() {
        let clock = SequencerClock()
        clock.bpm = 120
        // 120 BPM = 0.5s/beat, 16th = 0.5/4 = 0.125s
        XCTAssertEqual(clock.stepInterval, 0.125, accuracy: 0.001)
    }

    func testStepIntervalAt60BPM() {
        let clock = SequencerClock()
        clock.bpm = 60
        XCTAssertEqual(clock.stepInterval, 0.25, accuracy: 0.001)
    }

    func testSwingClampedHigh() {
        let clock = SequencerClock()
        clock.swing = 150
        XCTAssertLessThanOrEqual(clock.swing, 100)
    }

    func testSwingClampedLow() {
        let clock = SequencerClock()
        clock.swing = -10
        XCTAssertGreaterThanOrEqual(clock.swing, 0)
    }

    func testClockStartsAndStops() {
        let clock = SequencerClock()
        clock.start()
        XCTAssertTrue(clock.isRunning)
        clock.stop()
        XCTAssertFalse(clock.isRunning)
        XCTAssertEqual(clock.currentStep, 0)
    }

    func testClockTickFires() {
        let clock = SequencerClock()
        clock.bpm = 240  // fast
        let expectation = XCTestExpectation(description: "tick fires")
        clock.onTick = { _ in expectation.fulfill() }
        clock.start()
        wait(for: [expectation], timeout: 1.0)
        clock.stop()
    }
}
