import Foundation

struct Patch: Identifiable, Codable, Equatable {
    let id: UUID
    let fromModuleId: String
    let fromJackId: String
    let toModuleId: String
    let toJackId: String

    init(fromModuleId: String, fromJackId: String, toModuleId: String, toJackId: String) {
        self.id = UUID()
        self.fromModuleId = fromModuleId
        self.fromJackId = fromJackId
        self.toModuleId = toModuleId
        self.toJackId = toJackId
    }
}
