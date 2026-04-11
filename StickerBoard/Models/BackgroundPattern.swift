import SwiftUI

// MARK: - 背景パターン種別

enum BackgroundPatternType: String, Codable, CaseIterable, Identifiable {
    case solid = "solid"
    case dot = "dot"
    case grid = "grid"
    case stripe = "stripe"
    case gradient = "gradient"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .solid:    String(localized: "無地")
        case .dot:      String(localized: "ドット")
        case .grid:     String(localized: "グリッド")
        case .stripe:   String(localized: "ストライプ")
        case .gradient: String(localized: "グラデーション")
        case .custom:   String(localized: "写真")
        }
    }

    /// パターン選択UIに表示するケース（customはPhotosPickerで選択するため除外）
    static var pickerCases: [BackgroundPatternType] {
        allCases.filter { $0 != .custom }
    }

}

// MARK: - 背景パターン設定

struct BackgroundPatternConfig: Codable, Equatable {
    var patternType: BackgroundPatternType
    var primaryColorHex: String
    var secondaryColorHex: String
    var customImageFileName: String?
    /// カスタム背景画像の水平トリミング位置（0.0=左端 0.5=中央 1.0=右端）
    var customImageCropX: Double?
    /// カスタム背景画像の垂直トリミング位置（0.0=上端 0.5=中央 1.0=下端）
    var customImageCropY: Double?

    static let `default` = BackgroundPatternConfig(
        patternType: .solid,
        primaryColorHex: "FFFFFF",
        secondaryColorHex: "E5DDD0"
    )

    static let presets: [BackgroundPatternConfig] = [
        // 無地（白）
        BackgroundPatternConfig(patternType: .solid, primaryColorHex: "FFFFFF", secondaryColorHex: "FFFFFF"),
        // ドット（クラフト紙風）
        BackgroundPatternConfig(patternType: .dot, primaryColorHex: "FFF8F0", secondaryColorHex: "E5DDD0"),
        // グリッド（方眼紙風）
        BackgroundPatternConfig(patternType: .grid, primaryColorHex: "FFFFFF", secondaryColorHex: "D4E8D4"),
        // ストライプ（ポップ）
        BackgroundPatternConfig(patternType: .stripe, primaryColorHex: "FFF0F5", secondaryColorHex: "F2A7B0"),
        // グラデーション（ラベンダー〜ピンク）
        BackgroundPatternConfig(patternType: .gradient, primaryColorHex: "F2A7B0", secondaryColorHex: "C5B4E3"),
    ]
}

// MARK: - Hex文字列 ↔ Color 変換

extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            .sRGB,
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255,
            opacity: 1.0
        )
    }

    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(
            format: "%02X%02X%02X",
            Int(round(r * 255)),
            Int(round(g * 255)),
            Int(round(b * 255))
        )
    }
}
