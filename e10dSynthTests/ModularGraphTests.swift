import XCTest
@testable import e10dSynth

final class ModularGraphTests: XCTestCase {

    var graph: ModularGraph!

    override func setUp() {
        graph = ModularGraph()
    }

    func testAddModule() {
        let m = MockModule(id: "m1")
        graph.add(m)
        XCTAssertEqual(graph.modules.count, 1)
        XCTAssertNotNil(graph.modules["m1"])
    }

    func testRemoveModule() {
        let m = MockModule(id: "m1")
        graph.add(m)
        graph.remove("m1")
        XCTAssertEqual(graph.modules.count, 0)
    }

    func testConnectValidPatch() {
        let m1 = MockModule(id: "m1")
        let m2 = MockModule(id: "m2")
        graph.add(m1); graph.add(m2)
        let result = graph.connect(fromModule: "m1", fromJack: "audioOut",
                                    toModule: "m2", toJack: "audioIn")
        XCTAssertTrue(result)
        XCTAssertEqual(graph.patches.count, 1)
    }

    func testConnectInvalidMissingModule() {
        let result = graph.connect(fromModule: "missing", fromJack: "audioOut",
                                    toModule: "m2", toJack: "audioIn")
        XCTAssertFalse(result)
        XCTAssertEqual(graph.patches.count, 0)
    }

    func testConnectIncompatibleSignalTypes() {
        let m1 = MockModule(id: "m1", outputs: [Jack(id: "audioOut", name: "Out", signalType: .audio, direction: .output)])
        let m2 = MockModule(id: "m2", inputs: [Jack(id: "cvIn", name: "CV", signalType: .cv, direction: .input)])
        graph.add(m1); graph.add(m2)
        let result = graph.connect(fromModule: "m1", fromJack: "audioOut",
                                    toModule: "m2", toJack: "cvIn")
        XCTAssertFalse(result)
    }

    func testNoDuplicatePatches() {
        let m1 = MockModule(id: "m1")
        let m2 = MockModule(id: "m2")
        graph.add(m1); graph.add(m2)
        _ = graph.connect(fromModule: "m1", fromJack: "audioOut", toModule: "m2", toJack: "audioIn")
        _ = graph.connect(fromModule: "m1", fromJack: "audioOut", toModule: "m2", toJack: "audioIn")
        XCTAssertEqual(graph.patches.count, 1)
    }

    func testDisconnectPatch() {
        let m1 = MockModule(id: "m1")
        let m2 = MockModule(id: "m2")
        graph.add(m1); graph.add(m2)
        _ = graph.connect(fromModule: "m1", fromJack: "audioOut", toModule: "m2", toJack: "audioIn")
        let patchId = graph.patches.first!.id
        graph.disconnect(patchId)
        XCTAssertTrue(graph.patches.isEmpty)
    }

    func testRemoveModuleAlsoCleansPatches() {
        let m1 = MockModule(id: "m1")
        let m2 = MockModule(id: "m2")
        graph.add(m1); graph.add(m2)
        _ = graph.connect(fromModule: "m1", fromJack: "audioOut", toModule: "m2", toJack: "audioIn")
        graph.remove("m1")
        XCTAssertTrue(graph.patches.isEmpty)
    }
}

// MARK: - Test helpers
final class MockModule: SynthModule {
    let id: String
    let moduleType: ModuleType = .vco
    let name: String = "Mock"
    let inputs: [Jack]
    let outputs: [Jack]

    init(
        id: String,
        inputs: [Jack] = [Jack(id: "audioIn", name: "In", signalType: .audio, direction: .input)],
        outputs: [Jack] = [Jack(id: "audioOut", name: "Out", signalType: .audio, direction: .output)]
    ) {
        self.id = id
        self.inputs = inputs
        self.outputs = outputs
    }
}
