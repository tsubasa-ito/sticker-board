import SwiftUI

// MARK: - シールボード カラーテーマ
// 90年代シール手帳のノスタルジー × モダンUIの融合

enum AppTheme {

    // MARK: - メインカラー

    /// やわらかいコーラルピンク（アクセント）
    static let accent = Color(hex: 0xF2A7B0)
    /// ラベンダー（セカンダリ）
    static let secondary = Color(hex: 0xC5B4E3)
    /// ミントグリーン（サクセス・ポジティブ）
    static let mint = Color(hex: 0xA8E6CF)
    /// クリームイエロー（ハイライト）
    static let cream = Color(hex: 0xFFF5C3)
    /// ベビーブルー（情報・補助）
    static let baby = Color(hex: 0xB5D8F7)

    // MARK: - 背景

    /// メイン背景（温かみのあるオフホワイト）
    static let backgroundPrimary = Color(hex: 0xFFF8F0)
    /// カード背景
    static let backgroundCard = Color(hex: 0xFFFEFC)
    /// ボードのキャンバス背景（クラフト紙風）
    static let backgroundCanvas = Color(hex: 0xF5EDE0)

    // MARK: - テキスト

    static let textPrimary = Color(hex: 0x3D3236)
    static let textSecondary = Color(hex: 0x8E7E85)
    static let textTertiary = Color(hex: 0xBEB2B7)

    // MARK: - グラデーション

    static let headerGradient = LinearGradient(
        colors: [Color(hex: 0xF2A7B0), Color(hex: 0xC5B4E3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color(hex: 0xFFF8F0), Color(hex: 0xFFF0F5)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let mintGradient = LinearGradient(
        colors: [Color(hex: 0xA8E6CF), Color(hex: 0xB5D8F7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - 共通スタイル

extension View {
    /// シール手帳風のカードスタイル
    func stickerCard() -> some View {
        self
            .background(AppTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    /// グラスモーフィズム風カード
    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}
