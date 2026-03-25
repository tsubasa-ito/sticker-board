import Foundation
import SwiftData

@Model
final class Sticker {
    var id: UUID
    var imageFileName: String
    var createdAt: Date

    init(imageFileName: String) {
        self.id = UUID()
        self.imageFileName = imageFileName
        self.createdAt = Date()
    }
}
