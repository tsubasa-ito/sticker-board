import SwiftUI

// MARK: - シールボード カラーテーマ
// ネイビー × オレンジ — おしゃれな文房具屋さんの世界観

enum AppTheme {

    // MARK: - メインカラー

    /// ビビッドオレンジ（アクセント）
    static let accent = Color(hex: 0xE87A2E)
    /// ディープネイビー（セカンダリ）
    static let secondary = Color(hex: 0x2A2D5B)
    /// ソフトオレンジ（サクセス・ポジティブ）
    static let softOrange = Color(hex: 0xF0A870)
    /// クリームイエロー（ハイライト）
    static let cream = Color(hex: 0xFFF5C3)
    /// ベビーブルー（情報・補助）
    static let baby = Color(hex: 0xB5D8F7)

    // MARK: - 背景

    /// メイン背景（温かみのあるクリーム）
    static let backgroundPrimary = Color(hex: 0xFAF0DE)
    /// カード背景
    static let backgroundCard = Color(hex: 0xFFFEF8)
    /// ボードのキャンバス背景（クラフト紙風）
    static let backgroundCanvas = Color(hex: 0xF5EDE0)
    /// エディタ背景（薄いクリーム）
    static let editorBackground = Color(hex: 0xF2EDE4)
    /// ヒントトースト背景（ネイビー）
    static let editorDark = Color(hex: 0x2A2D5B)

    // MARK: - ボーダー・セパレータ

    /// 薄いボーダー
    static let borderSubtle = Color(hex: 0xE5DDD0)

    // MARK: - チェッカーボード

    static let checkerLight = Color(hex: 0xFFFEFC)
    static let checkerDark = Color(hex: 0xF0ECE6)

    // MARK: - テキスト

    /// ネイビー系プライマリテキスト
    static let textPrimary = Color(hex: 0x2A2D5B)
    /// ミディアムネイビー
    static let textSecondary = Color(hex: 0x6B6D8E)
    /// ライトネイビー
    static let textTertiary = Color(hex: 0xA0A2B8)

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

// MARK: - 画面サイズ（UIScreen.main 非推奨対応）

extension AppTheme {
    /// 現在のウィンドウシーンから画面サイズを取得する
    @MainActor
    static var screenBounds: CGRect {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else {
            return .zero
        }
        return scene.screen.bounds
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
