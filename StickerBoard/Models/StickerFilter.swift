import Foundation

// MARK: - シールフィルター種別

enum StickerFilter: String, Codable, CaseIterable, Identifiable {
    case original = "original"
    case sparkle = "sparkle"
    case retro = "retro"
    case pastel = "pastel"
    case neon = "neon"
    case puffy = "puffy"
    case wappen = "wappen"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .original: String(localized: "オリジナル")
        case .sparkle:  String(localized: "キラキラ")
        case .retro:    String(localized: "レトロ")
        case .pastel:   String(localized: "パステル")
        case .neon:     String(localized: "ネオン")
        case .puffy:    String(localized: "ぷっくり")
        case .wappen:   String(localized: "ワッペン")
        }
    }

    var iconName: String {
        switch self {
        case .original: "photo"
        case .sparkle: "sparkles"
        case .retro: "camera.filters"
        case .pastel: "paintpalette"
        case .neon: "bolt.fill"
        case .puffy: "circle.fill"
        case .wappen: "square.3.layers.3d"
        }
    }
}
