import Testing
import Foundation

/// ボード削除確認アラートのテスト
/// Issue #151: ボード削除時に確認ダイアログを表示する
///
/// 注意: このテストはソースコードを文字列として読み込み、文字列検索で構造を検証します。
/// HomeView.swift / BoardListView.swift の実装が変更された場合、
/// テストパターンも実態に合わせて更新してください。
struct BoardDeleteConfirmationTests {

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

    private var homeViewContent: String {
        get throws { try readFile("StickerBoard/Views/Home/HomeView.swift") }
    }

    private var boardListViewContent: String {
        get throws { try readFile("StickerBoard/Views/Board/BoardListView.swift") }
    }

    // MARK: - HomeView 削除確認

    @Test func homeView_削除対象ボードの状態変数が存在する() throws {
        let content = try homeViewContent
        #expect(content.contains("boardToDelete"), "boardToDelete状態変数が存在しません")
    }

    @Test func homeView_削除確認アラートが実装されている() throws {
        let content = try homeViewContent
        #expect(content.contains("削除しますか"), "削除確認アラートが実装されていません")
    }

    @Test func homeView_削除確認アラートに取り消せない旨のメッセージがある() throws {
        let content = try homeViewContent
        #expect(content.contains("取り消せません"), "「取り消せません」メッセージが実装されていません")
    }

    @Test func homeView_削除確認アラートのキャンセルボタンが存在する() throws {
        let content = try homeViewContent
        // 削除確認アラートのキャンセルボタン
        #expect(content.contains("role: .cancel"), "キャンセルボタンが設定されていません")
    }

    @Test func homeView_削除ボタンがdestructiveロールを使用している() throws {
        let content = try homeViewContent
        // 削除確認アラートの「削除」ボタンが .destructive ロールを持つ
        #expect(content.contains("role: .destructive"), "削除ボタンにdestructiveロールが設定されていません")
    }

    @Test func homeView_メニューの削除が即座に削除せず状態変数を設定する() throws {
        let content = try homeViewContent
        #expect(content.contains("boardToDelete = board"), "メニューの削除ボタンがboardToDeleteを設定していません")
    }

    // MARK: - BoardListView 削除確認

    @Test func boardListView_削除対象ボードの状態変数が存在する() throws {
        let content = try boardListViewContent
        #expect(content.contains("boardToDelete"), "boardToDelete状態変数が存在しません")
    }

    @Test func boardListView_削除確認アラートが実装されている() throws {
        let content = try boardListViewContent
        #expect(content.contains("削除しますか"), "削除確認アラートが実装されていません")
    }

    @Test func boardListView_削除確認アラートに取り消せない旨のメッセージがある() throws {
        let content = try boardListViewContent
        #expect(content.contains("取り消せません"), "「取り消せません」メッセージが実装されていません")
    }

    @Test func boardListView_contextMenuの削除が即座に削除せず状態変数を設定する() throws {
        let content = try boardListViewContent
        #expect(content.contains("boardToDelete = board"), "contextMenuの削除ボタンがboardToDeleteを設定していません")
    }
}
