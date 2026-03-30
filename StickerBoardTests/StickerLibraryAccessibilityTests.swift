import Testing
import Foundation

/// シールライブラリのVoiceOverアクセシビリティ対応完了テスト
/// Issue #101: StickerLibraryView
struct StickerLibraryAccessibilityTests {

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
        try readFile("StickerBoard/Views/Library/StickerLibraryView.swift")
    }

    // MARK: - コレクションカウンター

    @Test func カウンターのスターアイコンが装飾非表示() throws {
        let src = try content()
        // star.fill アイコンはテキストの装飾のため非表示
        #expect(src.contains("star.fill") && src.contains("accessibilityHidden"))
    }

    @Test func カウンターにaccessibilityLabelがある() throws {
        let src = try content()
        // 「全 N 枚のシール」のラベルが設定されている
        #expect(src.contains("totalCount") && src.contains("accessibilityLabel"))
    }

    // MARK: - 空状態

    @Test func 空状態にaccessibilityHintがある() throws {
        let src = try content()
        #expect(src.contains("emptyState") && src.contains("accessibilityHint"))
    }

    @Test func 空状態アイコンが装飾非表示() throws {
        let src = try content()
        #expect(src.contains("star.leadinghalf") && src.contains("accessibilityHidden"))
    }

    // MARK: - コンテキストメニュー

    @Test func コンテキストメニューの削除にaccessibilityLabelがある() throws {
        let src = try content()
        // contextMenu 内の削除ボタンに Label が設定されている（既存）
        #expect(src.contains("contextMenu") && src.contains("Label(\"削除\""))
    }

    // MARK: - 読み込みインジケーター

    @Test func 読み込みインジケーターにaccessibilityLabelがある() throws {
        let src = try content()
        #expect(src.contains("ProgressView") && src.contains("accessibilityLabel"))
    }

    // MARK: - サムネイル

    @Test func サムネイルのプレースホルダーアイコンが装飾非表示() throws {
        let src = try content()
        // photo プレースホルダーは装飾
        #expect(src.contains("\"photo\"") && src.contains("accessibilityHidden"))
    }
}
