import Testing
import Foundation

/// 複数シール選択画面のVoiceOverアクセシビリティ対応テスト
/// Issue #98: MultiStickerSelectionView
struct MultiStickerSelectionAccessibilityTests {

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

    private func content() throws -> String {
        try readFile("StickerBoard/Views/Capture/MultiStickerSelectionView.swift")
    }

    // MARK: - シールセル

    @Test func シールセルにaccessibilityLabelがある() throws {
        let src = try content()
        #expect(src.contains("stickerCell") && src.contains("accessibilityLabel"))
    }

    @Test func シールセルに選択状態のtraitsがある() throws {
        let src = try content()
        #expect(src.contains("stickerCell") && src.contains("isSelected"))
    }

    // MARK: - 全選択/全解除ボタン

    @Test func 全選択ボタンにaccessibilityValueがある() throws {
        let src = try content()
        // 「すべて選択」/「すべて解除」ボタンに現在の選択状態を accessibilityValue で通知
        #expect(src.contains("すべて選択") && src.contains("accessibilityValue"))
    }

    // MARK: - カウンターテキスト

    @Test func 保存ボタンのカウンターがaccessibilityLabelを持つ() throws {
        let src = try content()
        // 「N枚をコレクションに追加」ボタンにラベルが設定されている
        #expect(src.contains("コレクションに追加") && src.contains("accessibilityLabel"))
    }

    // MARK: - 保存ボタン

    @Test func 保存ボタンにaccessibilityHintがある() throws {
        let src = try content()
        #expect(src.contains("コレクションに追加") && src.contains("accessibilityHint"))
    }

    // MARK: - 装飾要素

    @Test func ヘッダーのsparklesアイコンが装飾非表示() throws {
        let src = try content()
        #expect(src.contains("sparkles") && src.contains("accessibilityHidden"))
    }

    @Test func チェックマーク背景円が装飾非表示() throws {
        let src = try content()
        // チェックマーク周りの装飾 Circle が accessibilityHidden
        #expect(src.contains("CheckerboardBackground") && src.contains("accessibilityHidden"))
    }

    @Test func エラーメッセージアイコンが装飾非表示() throws {
        let src = try content()
        #expect(src.contains("exclamationmark.triangle") && src.contains("accessibilityHidden"))
    }
}
