import Testing
import Foundation

/// ボード編集画面のピンチジェスチャーパフォーマンステスト
/// Issue #221: ボード内でのシールの操作を拡大縮小を続けるとクラッシュする
///
/// ## 問題の背景
/// 高速なピンチ操作を繰り返すと、onGestureEnded ごとに syncBoardToWidget() が発火し、
/// 各呼び出しで3つのImageRenderer（medium/large/small）が生成される。
/// ImageRendererは数MBのUIImageをメモリに確保するため、連続発火でメモリ圧迫→クラッシュ。
///
/// ## 修正方針
/// syncBoardToWidget() の呼び出しをデバウンスし、
/// 連続したジェスチャー操作では最後の操作から一定時間後のみ実行する。
///
/// 注意: このテストはソースコードを文字列として読み込み、パターンマッチで構造を検証します。
/// BoardEditorView.swift のメソッド名・構造が変更された場合、
/// テストのパターンマッチを実態に合わせて更新してください。
struct BoardEditorPinchPerformanceTests {

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

    // MARK: - デバウンス機構

    @Test func widgetSyncDebounceTask状態変数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("widgetSyncDebounceTask"),
                "widgetSyncDebounceTask状態変数が定義されていません")
    }

    @Test func debouncedSyncBoardToWidget関数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("func debouncedSyncBoardToWidget()"),
                "debouncedSyncBoardToWidget()関数が定義されていません")
    }

    @Test func debouncedSyncBoardToWidgetがTask_sleepでデバウンスしている() throws {
        let content = try editorContent
        let range = try #require(content.range(of: "func debouncedSyncBoardToWidget()"))
        let funcBody = content[range.lowerBound...]
        // 関数本体の閉じ括弧を探す
        var braceCount = 0
        var endIndex = funcBody.startIndex
        var started = false
        for idx in funcBody.indices {
            if funcBody[idx] == "{" {
                braceCount += 1
                started = true
            } else if funcBody[idx] == "}" {
                braceCount -= 1
            }
            endIndex = idx
            if started && braceCount == 0 { break }
        }
        let body = String(funcBody[funcBody.startIndex...endIndex])
        #expect(body.contains("Task.sleep"),
                "debouncedSyncBoardToWidget内でTask.sleepによるデバウンスが実装されていません")
    }

    @Test func saveBoardがdebouncedSyncBoardToWidgetを呼ぶ() throws {
        let content = try editorContent
        let range = try #require(content.range(of: "func saveBoard()"))
        let saveBoardBody = content[range.lowerBound...]
        // saveBoard関数の本体を抽出
        var braceCount = 0
        var endIndex = saveBoardBody.startIndex
        var started = false
        for idx in saveBoardBody.indices {
            if saveBoardBody[idx] == "{" {
                braceCount += 1
                started = true
            } else if saveBoardBody[idx] == "}" {
                braceCount -= 1
            }
            endIndex = idx
            if started && braceCount == 0 { break }
        }
        let body = String(saveBoardBody[saveBoardBody.startIndex...endIndex])
        #expect(body.contains("debouncedSyncBoardToWidget()"),
                "saveBoard内でdebouncedSyncBoardToWidget()を呼んでいません（直接syncBoardToWidget()を呼ぶとクラッシュの原因になります）")
    }

    // MARK: - onDisappear でのタスクキャンセル

    @Test func onDisappearでwidgetSyncTaskがキャンセルされる() throws {
        let content = try editorContent
        let range = try #require(content.range(of: ".onDisappear"))
        let onDisappearBody = content[range.lowerBound...]
        var braceCount = 0
        var endIndex = onDisappearBody.startIndex
        var started = false
        for idx in onDisappearBody.indices {
            if onDisappearBody[idx] == "{" {
                braceCount += 1
                started = true
            } else if onDisappearBody[idx] == "}" {
                braceCount -= 1
            }
            endIndex = idx
            if started && braceCount == 0 { break }
        }
        let body = String(onDisappearBody[onDisappearBody.startIndex...endIndex])
        #expect(body.contains("widgetSyncTask?.cancel()"),
                "onDisappear内でwidgetSyncTask?.cancel()が呼ばれていません（タスクリークの原因）")
    }

    @Test func onDisappearでwidgetSyncDebounceTaskがキャンセルされる() throws {
        let content = try editorContent
        let range = try #require(content.range(of: ".onDisappear"))
        let onDisappearBody = content[range.lowerBound...]
        var braceCount = 0
        var endIndex = onDisappearBody.startIndex
        var started = false
        for idx in onDisappearBody.indices {
            if onDisappearBody[idx] == "{" {
                braceCount += 1
                started = true
            } else if onDisappearBody[idx] == "}" {
                braceCount -= 1
            }
            endIndex = idx
            if started && braceCount == 0 { break }
        }
        let body = String(onDisappearBody[onDisappearBody.startIndex...endIndex])
        #expect(body.contains("widgetSyncDebounceTask?.cancel()"),
                "onDisappear内でwidgetSyncDebounceTask?.cancel()が呼ばれていません")
    }
}
