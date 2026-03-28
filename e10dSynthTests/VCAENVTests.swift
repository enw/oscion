import XCTest
@testable import e10dSynth

final class VCAENVTests: XCTestCase {

    // MARK: VCA
    func testVCAInputJacks() {
        let vca = VCAModule()
        XCTAssertTrue(vca.inputs.contains { $0.id == "audioIn" && $0.signalType == .audio })
        XCTAssertTrue(vca.inputs.contains { $0.id == "cvGain" && $0.signalType == .cv })
    }

    func testVCAOutputJack() {
        let vca = VCAModule()
        XCTAssertTrue(vca.outputs.contains { $0.id == "audioOut" })
    }

    func testVCAGainClamped() {
        let vca = VCAModule()
        vca.gain = 5.0
        XCTAssertLessThanOrEqual(vca.gain, 2.0)
        vca.gain = -1.0
        XCTAssertGreaterThanOrEqual(vca.gain, 0)
    }

    // MARK: ENV
    func testENVInputJack() {
        let env = ENVModule()
        XCTAssertTrue(env.inputs.contains { $0.id == "gateIn" && $0.signalType == .gate })
    }

    func testENVOutputJack() {
        let env = ENVModule()
        XCTAssertTrue(env.outputs.contains { $0.id == "cvOut" && $0.signalType == .cv })
    }

    func testENVAttackClampedLow() {
        let env = ENVModule()
        env.attack = -1
        XCTAssertGreaterThanOrEqual(env.attack, 0)
    }

    func testENVDecayClamped() {
        let env = ENVModule()
        env.decay = 100
        XCTAssertLessThanOrEqual(env.decay, 10)
    }

    func testENVSustainClamped() {
        let env = ENVModule()
        env.sustain = 2.0
        XCTAssertLessThanOrEqual(env.sustain, 1.0)
        env.sustain = -0.5
        XCTAssertGreaterThanOrEqual(env.sustain, 0)
    }

    func testENVTriggerAndRelease() {
        let env = ENVModule()
        XCTAssertFalse(env.isOpen)
        env.trigger()
        XCTAssertTrue(env.isOpen)
        env.releaseGate()
        XCTAssertFalse(env.isOpen)
    }

    func testENVModuleType() {
        XCTAssertEqual(ENVModule().moduleType, .env)
    }
}
