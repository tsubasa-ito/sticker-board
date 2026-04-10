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

// MARK: - エディタレイアウト定数

extension AppTheme {
    enum EditorLayout {
        /// エディタのナビバー(~56pt) + padding上下(24pt×2) + ツールバー領域(~140pt)
        static let verticalChromeHeight: CGFloat = 244
        /// エディタのキャンバス左右パディング
        static let horizontalPadding: CGFloat = 24
    }
}

// MARK: - 画面サイズ（UIScreen.main 非推奨対応）

extension AppTheme {
    /// 現在のウィンドウシーンから画面サイズを取得する
    @MainActor
    static var screenBounds: CGRect {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        // foregroundActive を優先し、なければ任意の接続済みシーンにフォールバック
        if let active = scenes.first(where: { $0.activationState == .foregroundActive }) {
            return active.screen.bounds
        }
        if let scene = scenes.first {
            return scene.screen.bounds
        }
        return .zero
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

    /// 選択状態を持つプランカード（選択時はアクセントカラーの薄い背景＋強いシャドウ）
    func selectableCard(isSelected: Bool) -> some View {
        self
            .background(
                isSelected ? AppTheme.accent.opacity(0.06) : AppTheme.backgroundCard,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .shadow(
                color: isSelected ? AppTheme.accent.opacity(0.22) : .black.opacity(0.06),
                radius: isSelected ? 10 : 6,
                x: 0,
                y: isSelected ? 5 : 3
            )
    }

    /// アクセントカラーの主要CTAボタン（設定・ペイウォール等で共通）
    func primaryButton() -> some View {
        self
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Pro特典データ

/// SettingsView・PaywallView で共用するPro特典定義
enum ProBenefit: CaseIterable, Identifiable {
    case stickerStorage
    case boardCreation
    case borderVariations
    case backgroundPatterns
    case exportWithoutLogo

    var id: Self { self }

    var icon: String {
        switch self {
        case .stickerStorage:     return "star.fill"
        case .boardCreation:      return "rectangle.on.rectangle.fill"
        case .borderVariations:   return "square.dashed"
        case .backgroundPatterns: return "paintpalette.fill"
        case .exportWithoutLogo:  return "square.and.arrow.down.fill"
        }
    }

    var title: String {
        switch self {
        case .stickerStorage:     return String(localized: "シール保存")
        case .boardCreation:      return String(localized: "ボード作成")
        case .borderVariations:   return String(localized: "枠線バリエーション")
        case .backgroundPatterns: return String(localized: "背景パターン")
        case .exportWithoutLogo:  return String(localized: "画像書き出し")
        }
    }

    var value: String {
        switch self {
        case .stickerStorage:     return String(localized: "無制限")
        case .boardCreation:      return String(localized: "無制限")
        case .borderVariations:   return String(localized: "全開放")
        case .backgroundPatterns: return String(localized: "全開放")
        case .exportWithoutLogo:  return String(localized: "ロゴなし")
        }
    }

    var iconColor: Color {
        switch self {
        case .stickerStorage:     return AppTheme.accent
        case .boardCreation:      return AppTheme.secondary
        case .borderVariations:   return AppTheme.softOrange
        case .backgroundPatterns: return AppTheme.baby
        case .exportWithoutLogo:  return AppTheme.secondary
        }
    }
}
