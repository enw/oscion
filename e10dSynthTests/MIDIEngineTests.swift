import XCTest
@testable import e10dSynth

final class MIDIEngineTests: XCTestCase {

    func testMIDIEngineInitializes() {
        let midi = MIDIEngine()
        XCTAssertNotNil(midi)
        XCTAssertFalse(midi.isConnected)
    }

    func testStartSetsConnected() {
        let midi = MIDIEngine()
        midi.start()
        XCTAssertTrue(midi.isConnected)
        midi.stop()
        XCTAssertFalse(midi.isConnected)
    }

    func testReceiveChannelClampedHigh() {
        let midi = MIDIEngine()
        midi.receiveChannel = 17
        XCTAssertLessThanOrEqual(midi.receiveChannel, 16)
    }

    func testReceiveChannelClampedLow() {
        let midi = MIDIEngine()
        midi.receiveChannel = 0
        XCTAssertGreaterThanOrEqual(midi.receiveChannel, 1)
    }

    func testSendChannelClamped() {
        let midi = MIDIEngine()
        midi.sendChannel = 20
        XCTAssertLessThanOrEqual(midi.sendChannel, 16)
    }

    func testNoteToFrequencyA440() {
        XCTAssertEqual(MIDIEngine.noteToFrequency(69), 440.0, accuracy: 0.01)
    }

    func testNoteToFrequencyA3() {
        XCTAssertEqual(MIDIEngine.noteToFrequency(57), 220.0, accuracy: 0.01)
    }

    func testNoteOnCallbackFires() {
        let midi = MIDIEngine()
        var receivedNote: Int? = nil
        var receivedVel: Int? = nil
        midi.onNoteOn = { note, vel in
            receivedNote = note
            receivedVel = vel
        }
        midi.onNoteOn?(60, 100)
        XCTAssertEqual(receivedNote, 60)
        XCTAssertEqual(receivedVel, 100)
    }

    func testMIDIInModuleJacks() {
        let m = MIDIInModule()
        XCTAssertTrue(m.outputs.contains { $0.id == "gateOut" && $0.signalType == .gate })
        XCTAssertTrue(m.outputs.contains { $0.id == "cvPitch" && $0.signalType == .cv })
        XCTAssertTrue(m.inputs.isEmpty)
    }

    func testMIDIOutModuleJacks() {
        let m = MIDIOutModule()
        XCTAssertTrue(m.inputs.contains { $0.id == "gateIn" && $0.signalType == .gate })
        XCTAssertTrue(m.inputs.contains { $0.id == "cvPitch" && $0.signalType == .cv })
        XCTAssertTrue(m.outputs.isEmpty)
    }
}
