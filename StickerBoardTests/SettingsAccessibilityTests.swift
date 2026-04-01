import Testing
import Foundation

/// 設定画面のVoiceOverアクセシビリティ対応テスト
/// Issue #97: SettingsView
struct SettingsAccessibilityTests {

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

    // MARK: - セクションヘッダーアイコン

    @Test func セクションヘッダーアイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // sectionHeader 内のアイコンは装飾目的のため accessibilityHidden
        #expect(content.contains("sectionHeader") && content.contains("accessibilityHidden"))
    }

    // MARK: - サブスクリプションセクション

    @Test func プランアイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // planRow 内の person.crop.circle アイコンは装飾
        #expect(content.contains("person.crop.circle") && content.contains("accessibilityHidden"))
    }

    @Test func プラン行がaccessibilityElementでグループ化() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // planRow をグループ化して「現在のプラン: Pro」のように読み上げ
        #expect(content.contains("planRow") && content.contains("accessibilityElement"))
    }

    @Test func 有効期限アイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // expirationRow 内の calendar アイコンは装飾
        #expect(content.contains("calendar") && content.contains("accessibilityHidden"))
    }

    @Test func 有効期限行がaccessibilityElementでグループ化() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // expirationRow をグループ化
        #expect(content.contains("expirationRow") && content.contains("accessibilityElement"))
    }

    @Test func ステータスアイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // statusRow 内の checkmark.seal / xmark.seal アイコンは装飾
        #expect(content.contains("checkmark.seal") && content.contains("accessibilityHidden"))
    }

    @Test func ステータス行がaccessibilityElementでグループ化() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // statusRow をグループ化して「ステータス: 有効」のように読み上げ
        #expect(content.contains("statusRow") && content.contains("accessibilityElement"))
    }

    // MARK: - プランカード

    @Test func プランカードにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // planCard にプラン名・価格を含むラベルを設定
        #expect(content.contains("planCard") && content.contains("accessibilityLabel"))
    }

    @Test func プランカードに選択状態のtraitsがある() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // planCard の選択状態を accessibilityAddTraits で通知
        #expect(content.contains("planCard") && content.contains("accessibilityAddTraits") && content.contains("isSelected"))
    }

    @Test func 割引バッジが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // 割引率バッジは planCard の accessibilityLabel に含めるため個別は非表示
        #expect(content.contains("badge") && content.contains("accessibilityHidden"))
    }

    // MARK: - 購入ボタン

    @Test func 購入ボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // 購入ボタンの状態変化をアクセシブルに
        #expect(content.contains("Pro にアップグレード") && content.contains("accessibilityLabel"))
    }

    @Test func 購入中のボタン状態がaccessibilityValueで通知() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // isPurchasing 時に accessibilityValue で状態を通知
        #expect(content.contains("isPurchasing") && content.contains("accessibilityValue"))
    }

    // MARK: - Proメリットセクション

    @Test func メリット行がaccessibilityElementでグループ化() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // benefitRow をグループ化して「シール保存: 無制限」のように読み上げ
        #expect(content.contains("benefitRow") && content.contains("accessibilityElement"))
    }

    @Test func メリットアイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // benefitRow 内のアイコンは装飾（グループ化ラベルで内容が伝わる）
        #expect(content.contains("benefitRow") && content.contains("accessibilityHidden"))
    }

    // MARK: - 関連リンク

    @Test func 外部リンクにaccessibilityHintがある() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // 利用規約・プライバシーポリシー等の外部リンクにヒントを追加
        #expect(content.contains("linkRow") && content.contains("accessibilityHint"))
    }

    @Test func 外部リンクアイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // arrow.up.right.square アイコンは装飾（ヒントで外部リンクであることを伝える）
        #expect(content.contains("arrow.up.right.square") && content.contains("accessibilityHidden"))
    }

    // MARK: - 復元ボタン

    @Test func 復元中のボタン状態がaccessibilityValueで通知() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // isRestoringPurchases 時に accessibilityValue で状態を通知
        #expect(content.contains("isRestoringPurchases") && content.contains("accessibilityValue"))
    }

    // MARK: - 注意事項セクション

    @Test func 注意事項の中黒が装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Settings/SettingsView.swift")
        // noticeItem 内の「・」は装飾テキスト
        #expect(content.contains("noticeItem") && content.contains("accessibilityHidden"))
    }
}
