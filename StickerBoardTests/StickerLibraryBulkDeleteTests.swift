import Testing
import Foundation

/// シールライブラリの一括削除機能テスト
/// Issue #271: シールライブラリでまとめて削除（一括削除）できるようにする
struct StickerLibraryBulkDeleteTests {

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

    private func libraryContent() throws -> String {
        try readFile("StickerBoard/Views/Library/StickerLibraryView.swift")
    }

    // MARK: - 選択モード用 State 変数

    @Test func isSelectionMode状態変数が存在する() throws {
        let src = try libraryContent()
        #expect(src.contains("isSelectionMode"),
                "StickerLibraryView に isSelectionMode 状態変数が存在しません")
    }

    @Test func selectedStickerIds状態変数が存在する() throws {
        let src = try libraryContent()
        #expect(src.contains("selectedStickerIds"),
                "StickerLibraryView に selectedStickerIds 状態変数が存在しません")
    }

    // MARK: - 「選択」ボタン

    @Test func ナビバーに選択ボタンが存在する() throws {
        let src = try libraryContent()
        #expect(src.contains("\"選択\""),
                "ナビゲーションバーに「選択」ボタンが存在しません")
    }

    @Test func 選択モード中にキャンセルボタンが存在する() throws {
        let src = try libraryContent()
        #expect(src.contains("isSelectionMode") && src.contains("\"キャンセル\""),
                "選択モード中のキャンセルボタンが存在しません")
    }

    @Test func ピッカーモード時は選択ボタンが非表示になる() throws {
        let src = try libraryContent()
        // isPicking（onStickerPicked != nil）時は選択ボタンを非表示にする条件分岐が必要
        #expect(src.contains("isPicking") && src.contains("isSelectionMode"),
                "ピッカーモード時に選択ボタンを非表示にする制御が存在しません")
    }

    // MARK: - チェックインジケーター

    @Test func 選択中シールにチェックインジケーターが表示される() throws {
        let src = try libraryContent()
        // チェックマーク（checkmark.circle.fill 等）が実装されている
        #expect(src.contains("checkmark.circle"),
                "選択状態のチェックインジケーターが存在しません")
    }

    @Test func 選択状態のアクセシビリティTraitが設定されている() throws {
        let src = try libraryContent()
        #expect(src.contains("isSelected") && src.contains("selectedStickerIds"),
                "VoiceOver 用の isSelected trait が設定されていません")
    }

    // MARK: - 「すべて選択/解除」ボタン

    @Test func すべて選択ボタンが存在する() throws {
        let src = try libraryContent()
        #expect(src.contains("すべて選択"),
                "「すべて選択」ボタンが存在しません")
    }

    // MARK: - 削除確認アラート

    @Test func 一括削除確認アラートが存在する() throws {
        let src = try libraryContent()
        #expect(src.contains("showBulkDeleteConfirm") || src.contains("bulkDelete"),
                "一括削除確認アラートが実装されていません")
    }

    @Test func 削除ボタンが選択数に応じて活性化される() throws {
        let src = try libraryContent()
        // selectedStickerIds.isEmpty による disabled 制御が存在する
        #expect(src.contains("selectedStickerIds.isEmpty"),
                "削除ボタンの活性/非活性制御が存在しません")
    }

    // MARK: - 一括削除処理

    @Test func 一括削除処理メソッドが存在する() throws {
        let src = try libraryContent()
        #expect(src.contains("bulkDelete") || src.contains("deleteSelectedStickers"),
                "一括削除処理メソッドが存在しません")
    }

    @Test func 一括削除後にwidgetSyncが呼ばれる() throws {
        let src = try libraryContent()
        #expect(src.contains("WidgetDataSyncService") || src.contains("syncBoard"),
                "一括削除後のウィジェット同期が実装されていません")
    }
}
