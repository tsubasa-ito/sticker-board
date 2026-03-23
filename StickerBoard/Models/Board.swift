import Foundation
import SwiftData

@Model
final class Board {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var placementsData: Data?

    var placements: [StickerPlacement] {
        get {
            guard let data = placementsData else { return [] }
            return (try? JSONDecoder().decode([StickerPlacement].self, from: data)) ?? []
        }
        set {
            placementsData = try? JSONEncoder().encode(newValue)
        }
    }

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.placementsData = nil
    }
}
