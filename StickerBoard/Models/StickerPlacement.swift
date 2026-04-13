import Foundation

struct StickerPlacement: Codable, Identifiable {
    var id: UUID
    var stickerId: UUID
    var imageFileName: String
    var positionX: Double
    var positionY: Double
    var scale: Double
    var rotation: Double
    var zIndex: Int
    var filterType: String = "original"
    var borderWidthType: String = "none"
    var borderColorHex: String = "FFFFFF"
    var isLocked: Bool = false

    init(stickerId: UUID, imageFileName: String, positionX: Double = 0, positionY: Double = 0, scale: Double = 1.0, rotation: Double = 0, zIndex: Int = 0, filterType: StickerFilter = .original, borderWidth: StickerBorderWidth = .none, borderColorHex: String = "FFFFFF") {
        self.id = UUID()
        self.stickerId = stickerId
        self.imageFileName = imageFileName
        self.positionX = positionX
        self.positionY = positionY
        self.scale = scale
        self.rotation = rotation
        self.zIndex = zIndex
        self.filterType = filterType.rawValue
        self.borderWidthType = borderWidth.rawValue
        self.borderColorHex = borderColorHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        stickerId = try container.decode(UUID.self, forKey: .stickerId)
        imageFileName = try container.decode(String.self, forKey: .imageFileName)
        positionX = try container.decode(Double.self, forKey: .positionX)
        positionY = try container.decode(Double.self, forKey: .positionY)
        scale = try container.decode(Double.self, forKey: .scale)
        rotation = try container.decode(Double.self, forKey: .rotation)
        zIndex = try container.decode(Int.self, forKey: .zIndex)
        filterType = try container.decodeIfPresent(String.self, forKey: .filterType) ?? "original"
        borderWidthType = try container.decodeIfPresent(String.self, forKey: .borderWidthType) ?? "none"
        borderColorHex = try container.decodeIfPresent(String.self, forKey: .borderColorHex) ?? "FFFFFF"
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
    }

    /// 現在のフィルター種別
    var filter: StickerFilter {
        get { StickerFilter(rawValue: filterType) ?? .original }
        set { filterType = newValue.rawValue }
    }

    /// 現在の枠線の太さ
    var borderWidth: StickerBorderWidth {
        get { StickerBorderWidth(rawValue: borderWidthType) ?? .none }
        set { borderWidthType = newValue.rawValue }
    }

    /// 枠線が設定されているか
    var hasBorder: Bool {
        borderWidth != .none
    }
}
