import SwiftUI

// MARK: - 背景パターン種別

enum BackgroundPatternType: String, Codable, CaseIterable, Identifiable {
    case solid = "solid"
    case dot = "dot"
    case grid = "grid"
    case stripe = "stripe"
    case gradient = "gradient"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .solid: "無地"
        case .dot: "ドット"
        case .grid: "グリッド"
        case .stripe: "ストライプ"
        case .gradient: "グラデーション"
        }
    }

}

// MARK: - 背景パターン設定

struct BackgroundPatternConfig: Codable, Equatable {
    var patternType: BackgroundPatternType
    var primaryColorHex: String
    var secondaryColorHex: String

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
}
