import Testing
import Foundation

/// BoardShareService の非同期化テスト
/// Issue #210: ImageRenderer の非同期化でシェア・保存時のUIフリーズを防止
///
/// 注意: このテストはソースコードを文字列として読み込み、パターンで構造を検証します。
/// 対象ソースの構造が変更された場合はテストのパターンを実態に合わせて更新してください。
struct BoardShareServiceTests {

    // MARK: - ヘルパー

    private var projectRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // StickerBoardTests/
            .deletingLastPathComponent()   // project root
    }

    private func readFile(_ relativePath: String) throws -> String {
        let url = projectRootURL.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    private var shareServiceContent: String {
        get throws { try readFile("StickerBoard/Services/BoardShareService.swift") }
    }

    private var boardEditorContent: String {
        get throws { try readFile("StickerBoard/Views/Board/BoardEditorView.swift") }
    }

    // MARK: - BoardShareService: presentShareSheet の非同期化

    @Test func presentShareSheet_asyncキーワードが付いている() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("private static func presentShareSheet") &&
            content.contains("async"),
            "presentShareSheet が async になっていません"
        )
    }

    @Test func presentShareSheet_TaskDetachedパターンを使用している() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("Task.detached"),
            "presentShareSheet が Task.detached パターンを使用していません"
        )
    }

    @Test func presentShareSheet_awaitでImageRendererを作成している() throws {
        let content = try shareServiceContent
        // 非同期化後は await ImageRenderer(...) パターンで作成する必要がある
        #expect(
            content.contains("await ImageRenderer(content:"),
            "presentShareSheet が await ImageRenderer パターンを使用していません"
        )
    }

    // MARK: - BoardEditorView: saveBoardAsImage の非同期化

    @Test func saveBoardAsImage_asyncキーワードが付いている() throws {
        let content = try boardEditorContent
        #expect(
            content.contains("func saveBoardAsImage() async"),
            "saveBoardAsImage が async になっていません"
        )
    }

    @Test func saveBoardAsImage_ButtonアクションでTask経由で呼ばれる() throws {
        let content = try boardEditorContent
        // Button("保存") { Task { await saveBoardAsImage() } } のパターンを確認
        #expect(
            content.contains("await saveBoardAsImage()"),
            "saveBoardAsImage が Button アクション内で await 経由で呼ばれていません"
        )
    }

    @Test func saveBoardAsImage_awaitでImageRendererを作成している() throws {
        let content = try boardEditorContent
        // 非同期化後は await ImageRenderer(...) パターンで作成する必要がある
        #expect(
            content.contains("await ImageRenderer(content:"),
            "saveBoardAsImage が await ImageRenderer パターンを使用していません"
        )
    }

    // MARK: - BoardEditorView: shareBoardAsImage の非同期化

    @Test func shareBoardAsImage_asyncキーワードが付いているかTaskラップされている() throws {
        let content = try boardEditorContent
        let hasAsyncFunc = content.contains("func shareBoardAsImage() async")
        let hasTaskWrap = content.contains("Task {") && content.contains("shareBoardAsImage()")
        #expect(
            hasAsyncFunc || hasTaskWrap,
            "shareBoardAsImage が async または Task でラップされていません"
        )
    }
}
