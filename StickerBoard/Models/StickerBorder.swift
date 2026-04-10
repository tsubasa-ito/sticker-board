import Foundation
import UIKit

// MARK: - 枠線の太さ

enum StickerBorderWidth: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case thin = "thin"
    case medium = "medium"
    case thick = "thick"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:   String(localized: "なし")
        case .thin:   String(localized: "細")
        case .medium: String(localized: "中")
        case .thick:  String(localized: "太")
        }
    }

    /// 画像の短辺に対するボーダー幅の比率
    var radiusRatio: CGFloat {
        switch self {
        case .none: 0
        case .thin: 0.015
        case .medium: 0.03
        case .thick: 0.05
        }
    }
}

// MARK: - 枠線カラープリセット

struct StickerBorderColor: Identifiable, Equatable {
    let id: String
    let displayName: String
    let hex: String
    let color: UIColor

    init(id: String, displayName: String, hex: String) {
        self.id = id
        self.displayName = displayName
        self.hex = hex

        guard let hexValue = UInt(hex, radix: 16) else {
            self.color = .black
            return
        }

        self.color = UIColor(
            red: CGFloat((hexValue >> 16) & 0xFF) / 255.0,
            green: CGFloat((hexValue >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hexValue & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    static let presets: [StickerBorderColor] = [
        StickerBorderColor(id: "white",    displayName: String(localized: "ホワイト"),   hex: "FFFFFF"),
        StickerBorderColor(id: "black",    displayName: String(localized: "ブラック"),   hex: "000000"),
        StickerBorderColor(id: "pink",     displayName: String(localized: "ピンク"),     hex: "F2A7B0"),
        StickerBorderColor(id: "lavender", displayName: String(localized: "ラベンダー"), hex: "C5B4E3"),
        StickerBorderColor(id: "mint",     displayName: String(localized: "ミント"),     hex: "A8E6CF"),
        StickerBorderColor(id: "cream",    displayName: String(localized: "クリーム"),   hex: "FFF5C3"),
        StickerBorderColor(id: "blue",     displayName: String(localized: "ベビーブルー"), hex: "B5D8F7"),
        StickerBorderColor(id: "red",      displayName: String(localized: "レッド"),     hex: "E74C3C"),
        StickerBorderColor(id: "gold",     displayName: String(localized: "ゴールド"),   hex: "F1C40F"),
    ]

    static let defaultColor = presets[0]
}
