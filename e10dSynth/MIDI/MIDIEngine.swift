import Foundation
import CoreMIDI
import AudioKit

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

    private let midi = MIDI()

    init() {}

    // MARK: - Lifecycle

    func start() {
        midi.openInput()
        midi.openOutput()
        midi.addListener(self)
        isConnected = true
    }

    func stop() {
        midi.closeAllInputs()
        isConnected = false
    }

    // MARK: - Send

    func sendNoteOn(note: Int, velocity: Int, channel: Int? = nil) {
        let ch = MIDIChannel(channel ?? sendChannel)
        midi.sendNoteOnMessage(noteNumber: MIDINoteNumber(note),
                               velocity: MIDIVelocity(velocity),
                               channel: ch)
    }

    func sendNoteOff(note: Int, channel: Int? = nil) {
        let ch = MIDIChannel(channel ?? sendChannel)
        midi.sendNoteOffMessage(noteNumber: MIDINoteNumber(note), channel: ch)
    }

    func sendCC(_ cc: Int, value: Int, channel: Int? = nil) {
        let ch = MIDIChannel(channel ?? sendChannel)
        midi.sendControllerMessage(MIDIByte(cc), value: MIDIByte(value), channel: ch)
    }

    func sendClock() { midi.sendMessage([0xF8]) }
    func sendStart() { midi.sendMessage([0xFA]) }
    func sendStop()  { midi.sendMessage([0xFC]) }

    // MARK: - Utilities

    static func noteToFrequency(_ note: Int) -> Float {
        return 440.0 * pow(2.0, Float(note - 69) / 12.0)
    }
}

extension MIDIEngine: MIDIListener {
    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        guard Int(channel) + 1 == receiveChannel || receiveChannel == 0 else { return }
        onNoteOn?(Int(noteNumber), Int(velocity))
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        guard Int(channel) + 1 == receiveChannel || receiveChannel == 0 else { return }
        onNoteOff?(Int(noteNumber))
    }

    func receivedMIDIController(_ controller: MIDIByte, value: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        onCC?(Int(controller), Int(value))
    }

    func receivedMIDIClock(timeStamp: MIDITimeStamp?) {}
    func receivedMIDISetupChange() {}
    func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {}
    func receivedMIDINotification(notification: MIDINotification) {}
    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIAftertouch(_ pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIAftertouch(noteNumber: MIDINoteNumber, pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIProgramChange(_ program: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDISystemCommand(_ data: [MIDIByte], portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
}
