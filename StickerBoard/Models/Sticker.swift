import Foundation
import SwiftData

@Model
final class Sticker {
    var id: UUID
    var imageFileName: String
    var filteredImageFileName: String?
    var filterType: String
    var createdAt: Date

    init(imageFileName: String, filterType: StickerFilter = .original, filteredImageFileName: String? = nil) {
        self.id = UUID()
        self.imageFileName = imageFileName
        self.filterType = filterType.rawValue
        self.filteredImageFileName = filteredImageFileName
        self.createdAt = Date()
    }

    /// 表示用画像のファイル名（フィルター適用済みがあればそちらを優先）
    var displayImageFileName: String {
        filteredImageFileName ?? imageFileName
    }

    /// 現在のフィルター種別
    var filter: StickerFilter {
        get { StickerFilter(rawValue: filterType) ?? .original }
        set { filterType = newValue.rawValue }
    }
}
