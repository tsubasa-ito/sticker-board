import Testing
import Foundation

/// フィルター・ボーダー選択画面のVoiceOverアクセシビリティ対応テスト
/// Issue #96: StickerFilterPickerView・StickerBorderPickerView
struct FilterBorderAccessibilityTests {

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

    // MARK: - StickerFilterPickerView アクセシビリティ

    @Test func FilterPicker_フィルターボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerFilterPickerView.swift")
        #expect(content.contains("accessibilityLabel"))
    }

    @Test func FilterPicker_フィルターボタンに選択状態のtraitsがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerFilterPickerView.swift")
        #expect(content.contains("isSelected"))
    }

    @Test func FilterPicker_フィルタープレビュー画像が装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerFilterPickerView.swift")
        // プレビュー画像はボタンラベルで内容が伝わるため、重複を避けるために非表示
        #expect(content.contains("Image(uiImage: preview)") && content.contains(".accessibilityHidden(true)"))
    }

    @Test func FilterPicker_チェッカーボード背景が装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerFilterPickerView.swift")
        #expect(content.contains("CheckerboardBackground") && content.contains("accessibilityHidden"))
    }

    @Test func FilterPicker_ローディング中のProgressViewにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerFilterPickerView.swift")
        // ProgressView に accessibilityLabel が設定されている
        #expect(content.contains("ProgressView") && content.contains("accessibilityLabel"))
    }

    @Test func FilterPicker_フィルター名テキストが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerFilterPickerView.swift")
        // フィルター名テキストはボタンのラベルに含まれるため、個別テキストは装飾非表示
        #expect(content.contains("filter.displayName") && content.contains("accessibilityHidden"))
    }

    // MARK: - StickerBorderPickerView アクセシビリティ

    @Test func BorderPicker_プレビュー画像にaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Board/StickerBorderPickerView.swift")
        #expect(content.contains("accessibilityLabel"))
    }

    @Test func BorderPicker_プレビューのチェッカーボード背景が装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Board/StickerBorderPickerView.swift")
        #expect(content.contains("CheckerboardBackground") && content.contains("accessibilityHidden"))
    }

    @Test func BorderPicker_太さボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Board/StickerBorderPickerView.swift")
        // 枠線幅ボタンに displayName を含むラベルが設定されている
        #expect(content.contains("width.displayName") && content.contains("accessibilityLabel"))
    }

    @Test func BorderPicker_太さボタンに選択状態のtraitsがある() throws {
        let content = try readFile("StickerBoard/Views/Board/StickerBorderPickerView.swift")
        #expect(content.contains("isSelected") && content.contains("accessibilityAddTraits"))
    }

    @Test func BorderPicker_太さアイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Board/StickerBorderPickerView.swift")
        // borderWidthIcon（破線円・太さ円）は装飾のため非表示
        #expect(content.contains("borderWidthIcon") && content.contains("accessibilityHidden"))
    }

    @Test func BorderPicker_カラーボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Board/StickerBorderPickerView.swift")
        // 色名（displayName）を accessibilityLabel に設定
        #expect(content.contains("preset.displayName") && content.contains("accessibilityLabel"))
    }

    @Test func BorderPicker_カラーボタンに選択状態のtraitsがある() throws {
        let content = try readFile("StickerBoard/Views/Board/StickerBorderPickerView.swift")
        // 色選択ボタンの isSelected 状態で accessibilityAddTraits が設定されている
        let hasColorSelected = content.contains("selectedColorHex == preset.hex") && content.contains("accessibilityAddTraits")
        #expect(hasColorSelected)
    }

    @Test func BorderPicker_セクションラベルが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Board/StickerBorderPickerView.swift")
        // 「太さ」「カラー」のセクションラベルは装飾テキストのため非表示
        // （ボタン自体にラベルがあるので冗長な読み上げを避ける）
        let hasSectionHidden = content.contains("\"太さ\"") && content.contains("accessibilityHidden")
        #expect(hasSectionHidden)
    }

    @Test func BorderPicker_ProBadgeが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Board/StickerBorderPickerView.swift")
        // ProBadge は視覚的装飾のため VoiceOver から非表示
        #expect(content.contains("ProBadge") && content.contains("accessibilityHidden"))
    }
}
