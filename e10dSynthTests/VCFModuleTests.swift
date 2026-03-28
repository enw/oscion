import XCTest
@testable import e10dSynth

final class VCFModuleTests: XCTestCase {

    func testVCFInputJacks() {
        let vcf = VCFModule()
        XCTAssertTrue(vcf.inputs.contains { $0.id == "audioIn" && $0.signalType == .audio })
        XCTAssertTrue(vcf.inputs.contains { $0.id == "cvCutoff" && $0.signalType == .cv })
    }

    func testVCFOutputJack() {
        let vcf = VCFModule()
        XCTAssertTrue(vcf.outputs.contains { $0.id == "audioOut" })
    }

    func testVCFCutoffClampedHigh() {
        let vcf = VCFModule()
        vcf.cutoff = 30000
        XCTAssertLessThanOrEqual(vcf.cutoff, 20000)
    }

    func testVCFCutoffClampedLow() {
        let vcf = VCFModule()
        vcf.cutoff = -100
        XCTAssertGreaterThanOrEqual(vcf.cutoff, 20)
    }

    func testVCFResonanceClampedHigh() {
        let vcf = VCFModule()
        vcf.resonance = 2.0
        XCTAssertLessThanOrEqual(vcf.resonance, 0.99)
    }

    func testVCFResonanceClampedLow() {
        let vcf = VCFModule()
        vcf.resonance = -0.5
        XCTAssertGreaterThanOrEqual(vcf.resonance, 0)
    }

    func testVCFModuleType() {
        XCTAssertEqual(VCFModule().moduleType, .vcf)
    }
}
