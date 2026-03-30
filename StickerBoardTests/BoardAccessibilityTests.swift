import Testing
import Foundation

/// ボード一覧・背景パターン選択のVoiceOverアクセシビリティ対応テスト
/// Issue #95: BoardListView・BackgroundPatternPickerView・BoardBackgroundView
struct BoardAccessibilityTests {

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

    // MARK: - BoardListView アクセシビリティ

    @Test func BoardListView_新規ボード作成ボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Board/BoardListView.swift")
        // 「+」ボタンに accessibilityLabel が設定されている
        #expect(content.contains("plus") && content.contains("accessibilityLabel"))
    }

    @Test func BoardListView_空状態アイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Board/BoardListView.swift")
        // 空状態のアイコン（rectangle.on.rectangle.angled + Circle背景）は装飾のため非表示
        #expect(content.contains("accessibilityHidden"))
    }

    @Test func BoardListView_空状態メッセージにaccessibilityHintがある() throws {
        let content = try readFile("StickerBoard/Views/Board/BoardListView.swift")
        // 空状態メッセージにヒントテキストが設定されている
        #expect(content.contains("accessibilityHint"))
    }

    @Test func BoardCard_アクセシブルな説明がある() throws {
        let content = try readFile("StickerBoard/Views/Board/BoardListView.swift")
        // BoardCard に accessibilityLabel が設定されている
        #expect(content.contains("BoardCard") && content.contains("accessibilityLabel"))
    }

    @Test func BoardCard_chevronアイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Board/BoardListView.swift")
        // chevron.right アイコンは装飾のため accessibilityHidden
        #expect(content.contains("chevron.right") && content.contains("accessibilityHidden"))
    }

    @Test func BoardCard_ボードアイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Board/BoardListView.swift")
        // BoardCard 内のボードアイコン（rectangle.on.rectangle.angled）は装飾のため非表示
        // emptyState と BoardCard の両方に accessibilityHidden がある
        let occurrences = content.components(separatedBy: "accessibilityHidden").count - 1
        #expect(occurrences >= 2)
    }

    // MARK: - BackgroundPatternPickerView アクセシビリティ

    @Test func BackgroundPatternPickerView_パターンボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Board/BackgroundPatternPickerView.swift")
        // patternTypeButton に accessibilityLabel が設定されている
        #expect(content.contains("accessibilityLabel"))
    }

    @Test func BackgroundPatternPickerView_パターンボタンに選択状態がある() throws {
        let content = try readFile("StickerBoard/Views/Board/BackgroundPatternPickerView.swift")
        // 選択中のパターンに isSelected traits が設定されている
        #expect(content.contains("isSelected"))
    }

    @Test func BackgroundPatternPickerView_パターンボタンにaccessibilityValueがある() throws {
        let content = try readFile("StickerBoard/Views/Board/BackgroundPatternPickerView.swift")
        // パターン選択に accessibilityValue で選択中のパターン名を通知
        #expect(content.contains("accessibilityValue"))
    }

    @Test func BackgroundPatternPickerView_カラーピッカーにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Board/BackgroundPatternPickerView.swift")
        // ColorPicker に accessibilityLabel が設定されている
        #expect(content.contains("ColorPicker") && content.contains("accessibilityLabel"))
    }

    @Test func BackgroundPatternPickerView_写真選択ボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Board/BackgroundPatternPickerView.swift")
        // 写真選択ボタンに accessibilityLabel が設定されている
        #expect(content.contains("customPhotoButton") && content.contains("accessibilityLabel"))
    }

    @Test func BackgroundPatternPickerView_ProバッジがaccessibilityLabelに含まれる() throws {
        let content = try readFile("StickerBoard/Views/Board/BackgroundPatternPickerView.swift")
        // Pro バッジの情報がアクセシビリティラベルに含まれる（「Pro限定」等）
        #expect(content.contains("Pro") && content.contains("accessibilityLabel"))
    }

    @Test func BackgroundPatternPickerView_プレビュー背景パターンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Board/BackgroundPatternPickerView.swift")
        // パターンボタン内のプレビューパターンは装飾のため非表示
        #expect(content.contains("accessibilityHidden"))
    }

    @Test func BackgroundPatternPickerView_クロップジェスチャーにaccessibilityActionがある() throws {
        let content = try readFile("StickerBoard/Views/Board/BackgroundPatternPickerView.swift")
        // カスタム画像のドラッグジェスチャーに代替操作がある
        #expect(content.contains("accessibilityAction") || content.contains("accessibilityAdjustableAction"))
    }

    @Test func BackgroundPatternPickerView_ドラッグヒントにaccessibilityHintがある() throws {
        let content = try readFile("StickerBoard/Views/Board/BackgroundPatternPickerView.swift")
        // ドラッグで位置調整のヒントに accessibilityHint が設定されている
        #expect(content.contains("accessibilityHint"))
    }

    // MARK: - BoardBackgroundView アクセシビリティ

    @Test func BoardBackgroundView_背景パターンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Board/BoardBackgroundView.swift")
        // 背景パターンは装飾的要素のため accessibilityHidden
        #expect(content.contains("accessibilityHidden"))
    }

    @Test func BoardBackgroundView_カスタム画像にaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Board/BoardBackgroundView.swift")
        // カスタム画像背景に accessibilityLabel が設定されている
        #expect(content.contains("accessibilityLabel"))
    }
}
