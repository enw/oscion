import Foundation

@Observable
final class MIDIEngine {

    var receiveChannel: Int = 1 {
        didSet { receiveChannel = min(16, max(1, receiveChannel)) }
    }
    var sendChannel: Int = 1 {
        didSet { sendChannel = min(16, max(1, sendChannel)) }
    }

    var onNoteOn:  ((Int, Int) -> Void)?   // (note, velocity)
    var onNoteOff: ((Int) -> Void)?        // (note)
    var onCC:      ((Int, Int) -> Void)?   // (cc#, value)

    private(set) var isConnected: Bool = false

    init() {}

    // MARK: - Lifecycle
    func start() {
        // CoreMIDI setup goes here when AudioKit is wired up
        isConnected = true
    }

    func stop() {
        isConnected = false
    }

    // MARK: - Send
    func sendNoteOn(note: Int, velocity: Int, channel: Int? = nil) {
        // CoreMIDI send — stubbed until AudioKit resolved
        _ = channel ?? sendChannel
    }

    func sendNoteOff(note: Int, channel: Int? = nil) {
        // CoreMIDI send — stubbed
        _ = channel ?? sendChannel
    }

    func sendCC(_ cc: Int, value: Int, channel: Int? = nil) {
        // CoreMIDI send — stubbed
        _ = channel ?? sendChannel
    }

    func sendClock() {
        // sends 0xF8 — stubbed
    }

    func sendStart() {
        // sends 0xFA — stubbed
    }

    func sendStop() {
        // sends 0xFC — stubbed
    }

    // MARK: - Utilities
    static func noteToFrequency(_ note: Int) -> Float {
        return 440.0 * pow(2.0, Float(note - 69) / 12.0)
    }
}
