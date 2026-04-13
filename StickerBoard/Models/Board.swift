import Foundation
import SwiftData

enum BoardType: String, Codable {
    /// 壁紙・画像用（縦長キャンバス）
    case standard
    /// ウィジェット大用（364×382pt 比率）
    case widgetLarge
    /// ウィジェット中用（364×170pt 比率）
    case widgetMedium
    /// ウィジェット小用（154×154pt 正方形）
    case widgetSmall

    static let widgetLargeAspectRatio: CGFloat = 364.0 / 382.0
    static let widgetMediumAspectRatio: CGFloat = 364.0 / 170.0
    static let widgetSmallAspectRatio: CGFloat = 1.0
    static let widgetSmallSize = CGSize(width: 154, height: 154)
}

@Model
final class Board {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var placementsData: Data?
    var backgroundPatternData: Data?
    var boardTypeRawValue: String = BoardType.standard.rawValue

    var boardType: BoardType {
        get { BoardType(rawValue: boardTypeRawValue) ?? .standard }
        set { boardTypeRawValue = newValue.rawValue }
    }

    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    @Transient private var _cachedPlacements: [StickerPlacement]?
    @Transient private var _cachedPlacementsData: Data?
    @Transient private var _cachedBackgroundPattern: BackgroundPatternConfig?
    @Transient private var _cachedBackgroundPatternData: Data?

    var placements: [StickerPlacement] {
        get {
            if let cached = _cachedPlacements, _cachedPlacementsData == placementsData {
                return cached
            }
            let decoded = placementsData.flatMap { try? Self.decoder.decode([StickerPlacement].self, from: $0) } ?? []
            _cachedPlacements = decoded
            _cachedPlacementsData = placementsData
            return decoded
        }
        set {
            placementsData = try? Self.encoder.encode(newValue)
            _cachedPlacements = newValue
            _cachedPlacementsData = placementsData
        }
    }

    var backgroundPattern: BackgroundPatternConfig {
        get {
            if let cached = _cachedBackgroundPattern, _cachedBackgroundPatternData == backgroundPatternData {
                return cached
            }
            let decoded = backgroundPatternData.flatMap { try? Self.decoder.decode(BackgroundPatternConfig.self, from: $0) } ?? .default
            _cachedBackgroundPattern = decoded
            _cachedBackgroundPatternData = backgroundPatternData
            return decoded
        }
        set {
            backgroundPatternData = try? Self.encoder.encode(newValue)
            _cachedBackgroundPattern = newValue
            _cachedBackgroundPatternData = backgroundPatternData
        }
    }

    init(title: String, boardType: BoardType = .standard, now: Date = .now) {
        self.id = UUID()
        self.title = title
        self.createdAt = now
        self.updatedAt = now
        self.placementsData = nil
        self.backgroundPatternData = nil
        self.boardTypeRawValue = boardType.rawValue
    }
}
