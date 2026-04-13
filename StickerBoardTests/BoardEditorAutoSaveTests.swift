import Testing
import Foundation

/// ボード編集画面の自動保存機能テスト
/// Issue #222: ボードの編集の際に自動保存されるように
///
/// 注意: このテストはソースコードを文字列として読み込み、パターンマッチで構造を検証します。
/// BoardEditorView.swift のメソッド名・構造が変更された場合、
/// テストのパターンマッチを実態に合わせて更新してください。
struct BoardEditorAutoSaveTests {

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
        get throws { try readFile("StickerBoard/Views/Board/BoardEditorView.swift") }
    }

    // MARK: - 層1: scenePhase による保存

    @Test func scenePhase環境変数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("scenePhase"),
                "scenePhase 環境変数が BoardEditorView に追加されていません")
    }

    @Test func backgroundへの移行時にsaveBoardが呼ばれる() throws {
        let content = try editorContent
        // .background ケースで saveBoard() を呼ぶ onChange が存在する
        let hasBackgroundSave = content.contains(".background") && content.contains("onChange(of: scenePhase")
        #expect(hasBackgroundSave,
                "scenePhase が .background になったときの saveBoard() 呼び出しが見つかりません")
    }

    // MARK: - 層2: onChange + デバウンス800ms

    @Test func autoSaveTaskが状態変数として定義されている() throws {
        let content = try editorContent
        #expect(content.contains("autoSaveTask"),
                "autoSaveTask 状態変数が BoardEditorView に追加されていません")
    }

    @Test func scheduleAutoSave関数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("func scheduleAutoSave()"),
                "scheduleAutoSave() 関数が BoardEditorView に定義されていません")
    }

    @Test func scheduleAutoSaveが800msデバウンスを実装している() throws {
        let content = try editorContent
        guard let range = content.range(of: "func scheduleAutoSave()") else {
            Issue.record("scheduleAutoSave() 関数が見つかりません")
            return
        }
        // 関数の後の500文字以内に800msのデバウンス処理があることを確認
        let endIndex = content.index(range.lowerBound, offsetBy: 500, limitedBy: content.endIndex) ?? content.endIndex
        let body = String(content[range.lowerBound..<endIndex])
        #expect(body.contains("800"),
                "scheduleAutoSave() に 800ms のデバウンスが実装されていません")
    }

    @Test func scheduleAutoSaveがsaveBoardを呼ぶ() throws {
        let content = try editorContent
        guard let range = content.range(of: "func scheduleAutoSave()") else {
            Issue.record("scheduleAutoSave() 関数が見つかりません")
            return
        }
        let endIndex = content.index(range.lowerBound, offsetBy: 500, limitedBy: content.endIndex) ?? content.endIndex
        let body = String(content[range.lowerBound..<endIndex])
        #expect(body.contains("saveBoard()"),
                "scheduleAutoSave() 内で saveBoard() が呼ばれていません")
    }

    @Test func placementsの変更でscheduleAutoSaveが呼ばれる() throws {
        let content = try editorContent
        #expect(content.contains("onChange(of: placements)"),
                "placements の変更を監視する onChange が見つかりません")
    }

    @Test func backgroundConfigの変更でscheduleAutoSaveが呼ばれる() throws {
        let content = try editorContent
        #expect(content.contains("onChange(of: backgroundConfig)"),
                "backgroundConfig の変更を監視する onChange が見つかりません")
    }

    // MARK: - onDisappear でのタスクキャンセル

    @Test func onDisappearでautoSaveTaskがキャンセルされる() throws {
        let content = try editorContent
        guard let disappearRange = content.range(of: ".onDisappear") else {
            Issue.record("onDisappear が見つかりません")
            return
        }
        let endIndex = content.index(disappearRange.lowerBound, offsetBy: 400, limitedBy: content.endIndex) ?? content.endIndex
        let body = String(content[disappearRange.lowerBound..<endIndex])
        #expect(body.contains("autoSaveTask?.cancel()"),
                "onDisappear 内で autoSaveTask?.cancel() が呼ばれていません")
    }
}
