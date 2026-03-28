import Foundation

enum JackDirection: String, Codable {
    case input, output
}

struct Jack: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let signalType: SignalType
    let direction: JackDirection

    func canConnect(to other: Jack) -> Bool {
        guard direction == .output, other.direction == .input else { return false }
        return signalType == other.signalType
    }
}
