import Testing
import Foundation

/// ボード編集画面のフィルターキャッシュ並列化テスト
/// Issue #284: BoardEditorView の rebuildFilterCache() を並列化してボード表示の発熱・遅延を改善する
///
/// ## 問題の背景
/// rebuildFilterCache() が全シールのフィルター+枠線処理を直列で実行しているため、
/// シール枚数が増えるほど処理が重くなり発熱・遅延が発生する。
///
/// ## 修正方針
/// withTaskGroup を使った並列処理への置き換えで処理時間を大幅に短縮する。
///
/// 注意: このテストはソースコードを文字列として読み込み、パターンマッチで構造を検証します。
/// BoardEditorView.swift のメソッド名・構造が変更された場合、
/// テストのパターンマッチを実態に合わせて更新してください。
struct BoardEditorFilterCacheParallelTests {

    // MARK: - ファイル読み込みヘルパー

    private var projectRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func readFile(_ relativePath: String) throws -> String {
        let url = projectRootURL.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    private var editorContent: String {
        get throws { try readFile("StickerBoard/Views/Board/BoardEditorView.swift") }
    }

    // MARK: - 並列処理の実装確認

    @Test func rebuildFilterCacheがwithTaskGroupを使用している() throws {
        let content = try editorContent
        #expect(content.contains("withTaskGroup"),
                "rebuildFilterCache()がwithTaskGroupを使用していません")
    }

    @Test func rebuildFilterCacheがTask_detachedで起動されている() throws {
        let content = try editorContent
        #expect(content.contains("Task.detached"),
                "rebuildFilterCache()がTask.detachedで起動されていません")
    }

    @Test func rebuildFilterCacheがMainActorRunでUI反映している() throws {
        let content = try editorContent
        #expect(content.contains("MainActor.run"),
                "rebuildFilterCache()がMainActor.runでUI反映していません")
    }

    // MARK: - キャンセル機構の維持確認

    @Test func rebuildTaskキャンセルが維持されている() throws {
        let content = try editorContent
        #expect(content.contains("rebuildTask?.cancel()"),
                "rebuildTask?.cancel()によるキャンセル機構が失われています")
    }

    @Test func TaskIsCancelledチェックが実装されている() throws {
        let content = try editorContent
        #expect(content.contains("Task.isCancelled"),
                "Task.isCancelledによるキャンセルチェックが実装されていません")
    }

    // MARK: - キャッシュマージとクリーンアップの確認

    @Test func 既存キャッシュとのマージが実装されている() throws {
        let content = try editorContent
        #expect(content.contains("result.merge(loadedImages)"),
                "既存キャッシュとのマージ処理が実装されていません")
    }

    @Test func 不要キャッシュの除去が実装されている() throws {
        let content = try editorContent
        #expect(content.contains("currentIds"),
                "currentIdsによる不要キャッシュ除去が実装されていません")
    }
}
