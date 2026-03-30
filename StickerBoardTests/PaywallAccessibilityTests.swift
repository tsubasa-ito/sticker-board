import Testing
import Foundation

/// ペイウォール画面のVoiceOverアクセシビリティ対応テスト
/// Issue #97: PaywallView
struct PaywallAccessibilityTests {

    // MARK: - ファイル読み込みヘルパー

    private var projectRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // StickerBoardTests/
            .deletingLastPathComponent()   // project root
    }

    private func readFile(_ relativePath: String) throws -> String {
        let url = projectRootURL.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - ヘッダー

    @Test func 王冠アイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // ヘッダーの crown.fill アイコンは装飾目的
        #expect(content.contains("crown.fill") && content.contains("accessibilityHidden"))
    }

    @Test func 背景円が装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // アイコン背景の Circle は装飾
        #expect(content.contains("headerSection") && content.contains("accessibilityHidden"))
    }

    // MARK: - 機能リスト

    @Test func 機能行がaccessibilityElementでグループ化() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // featureRow をグループ化して「シール保存: 無制限」のように読み上げ
        #expect(content.contains("featureRow") && content.contains("accessibilityElement"))
    }

    @Test func 機能アイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // featureRow 内のアイコン背景円は装飾
        #expect(content.contains("featureRow") && content.contains("accessibilityHidden"))
    }

    // MARK: - 価格セクション

    @Test func 年額価格カードにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // 年額カード全体をアクセシブルなラベルでまとめる
        #expect(content.contains("pricingSection") && content.contains("accessibilityLabel"))
    }

    @Test func 割引バッジが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // 割引率バッジは価格カードの accessibilityLabel に含めるため個別は非表示
        #expect(content.contains("おトク") && content.contains("accessibilityHidden"))
    }

    // MARK: - 購入ボタン

    @Test func 年額購入ボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // 「Proではじめる（年額）」ボタンにラベル
        #expect(content.contains("Proではじめる") && content.contains("accessibilityLabel"))
    }

    @Test func 購入中のオーバーレイがアクセシビリティ通知される() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // isPurchasing 時の状態を accessibilityValue で通知
        #expect(content.contains("isPurchasing") && content.contains("accessibilityValue"))
    }

    @Test func 月額ボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // 月額プランボタンにアクセシブルなラベル
        #expect(content.contains("月額プランで始める") && content.contains("accessibilityLabel"))
    }

    // MARK: - フッター

    @Test func 利用規約リンクにaccessibilityHintがある() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // 利用規約リンクが外部リンクであることをヒントで通知
        #expect(content.contains("利用規約") && content.contains("accessibilityHint"))
    }

    @Test func プライバシーポリシーリンクにaccessibilityHintがある() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // プライバシーポリシーリンクが外部リンクであることをヒントで通知
        #expect(content.contains("プライバシーポリシー") && content.contains("accessibilityHint"))
    }

    // MARK: - ProBadge

    @Test func ProBadgeにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // ProBadge に accessibilityLabel を設定
        #expect(content.contains("ProBadge") && content.contains("accessibilityLabel"))
    }

    // MARK: - 購入中オーバーレイ

    @Test func 購入中オーバーレイの背景が装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Paywall/PaywallView.swift")
        // 購入中の半透明オーバーレイ背景は装飾
        #expect(content.contains("Color.black.opacity") && content.contains("accessibilityHidden"))
    }
}
