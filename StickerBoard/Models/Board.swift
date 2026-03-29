import Foundation
import SwiftData

@Model
final class Board {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var placementsData: Data?
    var backgroundPatternData: Data?

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
            guard let data = backgroundPatternData else { return .default }
            let decoded = (try? Self.decoder.decode(BackgroundPatternConfig.self, from: data)) ?? .default
            _cachedBackgroundPattern = decoded
            _cachedBackgroundPatternData = data
            return decoded
        }
        set {
            backgroundPatternData = try? Self.encoder.encode(newValue)
            _cachedBackgroundPattern = newValue
            _cachedBackgroundPatternData = backgroundPatternData
        }
    }

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.placementsData = nil
        self.backgroundPatternData = nil
    }
}
