import Testing
import Foundation

struct AccessibilityRuleTests {

    private let ruleRelativePath = ".claude/rules/accessibility-check.md"

    private var projectRootURL: URL {
        // テストファイルからプロジェクトルートへ遡る（ファイル移動時は要修正）
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // StickerBoardTests/
            .deletingLastPathComponent()   // project root
    }

    private func ruleContent() throws -> String {
        let url = projectRootURL.appendingPathComponent(ruleRelativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - ファイル存在

    @Test func ルールファイルが存在する() {
        let url = projectRootURL.appendingPathComponent(ruleRelativePath)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: - 必須セクション

    @Test func トリガー条件セクションがある() throws {
        let content = try ruleContent()
        #expect(content.contains("## トリガー条件"))
    }

    @Test func ルールセクションがある() throws {
        let content = try ruleContent()
        #expect(content.contains("## ルール"))
    }

    // MARK: - チェック項目

    @Test func Image_accessibilityLabelチェック項目がある() throws {
        let content = try ruleContent()
        #expect(content.contains("Image(systemName:)"))
        #expect(content.contains("Image(uiImage:)"))
        #expect(content.contains("accessibilityLabel"))
    }

    @Test func インタラクティブ要素のラベルチェック項目がある() throws {
        let content = try ruleContent()
        #expect(content.contains("Button"))
        #expect(content.contains("onTapGesture"))
    }

    @Test func 動的コンテンツの通知チェック項目がある() throws {
        let content = try ruleContent()
        #expect(content.contains("accessibilityValue"))
        #expect(content.contains("AccessibilityNotification"))
        #expect(content.contains("UIAccessibility.post"))
    }

    @Test func カスタムジェスチャーの代替チェック項目がある() throws {
        let content = try ruleContent()
        #expect(content.contains("accessibilityAction"))
    }

    @Test func 選択状態のtraitsチェック項目がある() throws {
        let content = try ruleContent()
        #expect(content.contains("isSelected"))
    }

    @Test func 装飾的要素の非表示チェック項目がある() throws {
        let content = try ruleContent()
        #expect(content.contains("accessibilityHidden"))
    }

    // MARK: - 対応フロー

    @Test func 対応フローが記載されている() throws {
        let content = try ruleContent()
        #expect(content.contains("修正されたViewファイルを確認") || content.contains("Viewファイルを確認"))
        #expect(content.contains("未対応箇所") || content.contains("未対応"))
    }

    // MARK: - 重大度・対象外セクション

    @Test func 重大度の判定基準が定義されている() throws {
        let content = try ruleContent()
        #expect(content.contains("### 重大度の判定基準"))
        #expect(content.contains("**高**"))
        #expect(content.contains("**中**"))
        #expect(content.contains("**低**"))
    }

    @Test func 対象外セクションが定義されている() throws {
        let content = try ruleContent()
        #expect(content.contains("## 対象外"))
    }

    // MARK: - 既存ルールとの一貫性

    @Test func ルール見出しが正しいプレフィックスで始まる() throws {
        let content = try ruleContent()
        #expect(content.hasPrefix("# ルール:"))
    }
}
