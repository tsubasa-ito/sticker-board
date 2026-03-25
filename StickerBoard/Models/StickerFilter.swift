import Foundation

// MARK: - シールフィルター種別

enum StickerFilter: String, Codable, CaseIterable, Identifiable {
    case original = "original"
    case sparkle = "sparkle"
    case retro = "retro"
    case pastel = "pastel"
    case neon = "neon"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .original: "オリジナル"
        case .sparkle: "キラキラ"
        case .retro: "レトロ"
        case .pastel: "パステル"
        case .neon: "ネオン"
        }
    }

    var iconName: String {
        switch self {
        case .original: "photo"
        case .sparkle: "sparkles"
        case .retro: "camera.filters"
        case .pastel: "paintpalette"
        case .neon: "bolt.fill"
        }
    }
}
