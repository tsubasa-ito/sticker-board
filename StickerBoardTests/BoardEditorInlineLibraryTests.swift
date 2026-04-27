import Testing
import Foundation

/// ボードエディタのインラインライブラリ統合テスト
/// Issue #235: ボードエディタにインラインライブラリを統合してシール追加のタップ数を削減
///
/// 注意: このテストはソースコードを文字列として読み込み、構造を検証します。
/// 対象コードの構造が変更された場合はテストのパターンマッチも更新してください。
struct BoardEditorInlineLibraryTests {

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

    private var editorContent: String {
        get throws {
            try readFile("StickerBoard/Views/Board/BoardEditorView.swift")
        }
    }

    // MARK: - インラインライブラリ state

    @Test func boardEditor_showingInlineLibrary状態変数が存在する() throws {
        let content = try editorContent
        #expect(content.contains("showingInlineLibrary"),
                "showingInlineLibrary 状態変数が BoardEditorView に存在しません")
    }

    @Test func boardEditor_showingInlineLibraryがfalseで初期化されている() throws {
        let content = try editorContent
        #expect(content.contains("showingInlineLibrary = false"),
                "showingInlineLibrary が false で初期化されていません")
    }

    // MARK: - シート表示

    @Test func boardEditor_showingInlineLibraryでシートが表示される() throws {
        let content = try editorContent
        #expect(content.contains("sheet(isPresented: $showingInlineLibrary"),
                "showingInlineLibrary に対応する .sheet modifier が見つかりません")
    }

    @Test func boardEditor_インラインライブラリシートにStickerLibraryViewが使用されている() throws {
        let content = try editorContent
        #expect(content.contains("StickerLibraryView"),
                "StickerLibraryView が BoardEditorView で使用されていません")
    }

    @Test func boardEditor_インラインライブラリシートにonStickerPickedコールバックが渡される() throws {
        let content = try editorContent
        #expect(content.contains("onStickerPicked"),
                "onStickerPicked コールバックが BoardEditorView で使用されていません")
    }

    // MARK: - 追加ボタンの動作

    @Test func boardEditor_追加ボタンがshowingInlineLibraryをtrueにする() throws {
        let content = try editorContent
        // "追加" ボタンの近くで showingInlineLibrary = true が設定されていること
        #expect(content.contains("showingInlineLibrary = true"),
                "追加ボタンが showingInlineLibrary = true に設定していません")
    }

    // MARK: - 旧実装の削除（QuickPicks は削除されている）

    @Test func boardEditor_showQuickPicksは削除されている() throws {
        let content = try editorContent
        #expect(!content.contains("showQuickPicks"),
                "旧実装の showQuickPicks が残存しています。インラインライブラリに移行してください")
    }

    @Test func boardEditor_showingStickerPickerは削除されている() throws {
        let content = try editorContent
        #expect(!content.contains("showingStickerPicker"),
                "旧実装の showingStickerPicker が残存しています。インラインライブラリに移行してください")
    }

    @Test func boardEditor_StickerPickerSheetは削除されている() throws {
        let content = try editorContent
        #expect(!content.contains("struct StickerPickerSheet"),
                "旧実装の StickerPickerSheet が残存しています。インラインライブラリに移行してください")
    }

    // MARK: - presentationDetents

    @Test func boardEditor_インラインライブラリシートにpresentationDetentsが設定されている() throws {
        let content = try editorContent
        #expect(content.contains("presentationDetents"),
                "インラインライブラリシートに presentationDetents が設定されていません")
    }
}
