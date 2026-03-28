import XCTest
@testable import e10dSynth

final class ModelTests: XCTestCase {

    func testSignalTypeRawValues() {
        XCTAssertEqual(SignalType.audio.rawValue, "audio")
        XCTAssertEqual(SignalType.cv.rawValue, "cv")
        XCTAssertEqual(SignalType.gate.rawValue, "gate")
    }

    func testJackDirectionIncompatibleOutputToOutput() {
        let out1 = Jack(id: "o1", name: "Out", signalType: .audio, direction: .output)
        let out2 = Jack(id: "o2", name: "Out2", signalType: .audio, direction: .output)
        XCTAssertFalse(out1.canConnect(to: out2))
    }

    func testJackInputCannotInitiateConnection() {
        let inp1 = Jack(id: "i1", name: "In", signalType: .audio, direction: .input)
        let inp2 = Jack(id: "i2", name: "In2", signalType: .audio, direction: .input)
        XCTAssertFalse(inp1.canConnect(to: inp2))
    }

    func testJackCompatibleAudioToAudio() {
        let out = Jack(id: "o1", name: "Out", signalType: .audio, direction: .output)
        let inp = Jack(id: "i1", name: "In", signalType: .audio, direction: .input)
        XCTAssertTrue(out.canConnect(to: inp))
    }

    func testJackIncompatibleAudioToCV() {
        let out = Jack(id: "o1", name: "Out", signalType: .audio, direction: .output)
        let inp = Jack(id: "i1", name: "In", signalType: .cv, direction: .input)
        XCTAssertFalse(out.canConnect(to: inp))
    }

    func testJackIncompatibleAudioToGate() {
        let out = Jack(id: "o1", name: "Out", signalType: .audio, direction: .output)
        let inp = Jack(id: "i1", name: "In", signalType: .gate, direction: .input)
        XCTAssertFalse(out.canConnect(to: inp))
    }

    func testPatchCodableRoundTrip() throws {
        let patch = Patch(
            fromModuleId: "m1", fromJackId: "j1",
            toModuleId: "m2", toJackId: "j2"
        )
        let data = try JSONEncoder().encode(patch)
        let decoded = try JSONDecoder().decode(Patch.self, from: data)
        XCTAssertEqual(patch.id, decoded.id)
        XCTAssertEqual(decoded.fromModuleId, "m1")
        XCTAssertEqual(decoded.toJackId, "j2")
    }

    func testModuleTypeAllCases() {
        let expected: [ModuleType] = [.vco, .vcf, .vca, .env, .lfo, .seq, .midiIn, .midiOut, .out]
        XCTAssertEqual(ModuleType.allCases, expected)
    }
}
