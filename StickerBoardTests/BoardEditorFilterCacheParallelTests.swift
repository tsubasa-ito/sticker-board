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
/// ## テストの注意事項（脆弱性について）
/// このテストはソースコードを文字列として読み込み、パターンマッチで構造を検証します。
/// SwiftUI View を直接インスタンス化できないため、このアプローチを採用しています。
///
/// **リファクタリング時の対処法:**
/// - BoardEditorView.swift のメソッド名・変数名・構造が変更された場合は、
///   テストのパターン文字列を実態に合わせて更新してください。
/// - テストが予期せず失敗した場合は、まず BoardEditorView.swift の該当箇所を確認し、
///   パターン文字列が実際のコードと一致しているかを検証してください。
/// - パターンが他の箇所にも存在する可能性があるため、文字列は可能な限り具体的に記述します。
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

    @Test func rebuildFilterCacheがTaskでMainActor隔離を継承して起動される() throws {
        let content = try editorContent
        // Task {} は @MainActor 隔離を継承するため Task.detached ではなく Task を使用する。
        // group.addTask クロージャは非隔離で並列実行されるため CPU 集約処理はバックグラウンドで動く。
        #expect(content.contains("rebuildTask = Task {"),
                "rebuildFilterCache()がMainActor隔離を継承するTask{}で起動されていません")
    }

    @Test func rebuildFilterCacheがMainActor上でloadedImagesを直接更新する() throws {
        let content = try editorContent
        // Task {} が @MainActor 隔離を継承するため MainActor.run 不要で直接 @State を更新できる
        #expect(content.contains("loadedImages = merged.filter"),
                "rebuildFilterCache()がMainActor上でloadedImagesを直接更新していません")
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

    // MARK: - キャンセル伝播の確認

    @Test func 集約ループでキャンセル時にgroupCancelAllが呼ばれる() throws {
        let content = try editorContent
        #expect(content.contains("group.cancelAll()"),
                "集約ループ内でgroup.cancelAll()によるキャンセル伝播が実装されていません")
    }

    // MARK: - キャッシュマージとクリーンアップの確認

    @Test func 既存キャッシュとのマージが実装されている() throws {
        let content = try editorContent
        #expect(content.contains("merged.merge(result)"),
                "loadedImagesをベースにresultで上書きするマージが実装されていません")
    }

    @Test func 不要キャッシュの除去が実装されている() throws {
        let content = try editorContent
        #expect(content.contains("let currentIds = Set(placements.map"),
                "let currentIds = Set(placements.map による不要キャッシュ除去が実装されていません")
    }
}
