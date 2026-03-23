import Foundation

struct StickerPlacement: Codable, Identifiable {
    var id: UUID
    var stickerId: UUID
    var positionX: Double
    var positionY: Double
    var scale: Double
    var rotation: Double
    var zIndex: Int

    init(stickerId: UUID, positionX: Double = 0, positionY: Double = 0, scale: Double = 1.0, rotation: Double = 0, zIndex: Int = 0) {
        self.id = UUID()
        self.stickerId = stickerId
        self.positionX = positionX
        self.positionY = positionY
        self.scale = scale
        self.rotation = rotation
        self.zIndex = zIndex
    }
}
