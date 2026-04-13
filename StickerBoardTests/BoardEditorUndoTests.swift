import Testing
import Foundation

/// ボード編集画面のUndo機能テスト
/// Issue #218: ボード編集画面で１つ戻る機能（undo）
///
/// 注意: このテストはソースコードを文字列として読み込み、パターンマッチで構造を検証します。
/// BoardEditorView.swift / StickerItemView.swift のメソッド名・構造が変更された場合、
/// テストのパターンマッチを実態に合わせて更新してください。
struct BoardEditorUndoTests {

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

    private var itemViewContent: String {
        get throws { try readFile("StickerBoard/Views/Board/StickerItemView.swift") }
    }

    // MARK: - Undoスタック状態変数

    @Test func undoStack状態変数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("var undoStack"))
    }

    @Test func undoStackの上限定数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("undoStackLimit"))
    }

    // MARK: - Undoスナップショット保存

    @Test func saveUndoSnapshot関数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("func saveUndoSnapshot()"))
    }

    @Test func saveUndoSnapshotがaddStickerToBoardで呼ばれる() throws {
        let content = try editorContent
        let range = try #require(content.range(of: "func addStickerToBoard"))
        let appendRange = try #require(content[range.lowerBound...].range(of: "placements.append"))
        let body = String(content[range.lowerBound..<appendRange.upperBound])
        #expect(body.contains("saveUndoSnapshot()"),
                "addStickerToBoard内でsaveUndoSnapshot()が呼ばれていません")
    }

    @Test func saveUndoSnapshotがremoveFromBoardで呼ばれる() throws {
        let content = try editorContent
        let range = try #require(content.range(of: "func removeFromBoard"))
        let removeRange = try #require(content[range.lowerBound...].range(of: "placements.removeAll"))
        let body = String(content[range.lowerBound..<removeRange.upperBound])
        #expect(body.contains("saveUndoSnapshot()"),
                "removeFromBoard内でsaveUndoSnapshot()が呼ばれていません")
    }

    @Test func saveUndoSnapshotがreorderAndNormalizeZIndexで呼ばれる() throws {
        let content = try editorContent
        let range = try #require(content.range(of: "func reorderAndNormalizeZIndex"))
        let saveBoardRange = try #require(content[range.lowerBound...].range(of: "saveBoard()"))
        let body = String(content[range.lowerBound..<saveBoardRange.upperBound])
        #expect(body.contains("saveUndoSnapshot()"),
                "reorderAndNormalizeZIndex内でsaveUndoSnapshot()が呼ばれていません")
    }

    @Test func saveUndoSnapshotがtoggleLockForSelectedで呼ばれる() throws {
        let content = try editorContent
        let range = try #require(content.range(of: "func toggleLockForSelected"))
        let saveBoardRange = try #require(content[range.lowerBound...].range(of: "saveBoard()"))
        let body = String(content[range.lowerBound..<saveBoardRange.upperBound])
        #expect(body.contains("saveUndoSnapshot()"),
                "toggleLockForSelected内でsaveUndoSnapshot()が呼ばれていません")
    }

    // MARK: - Undo実行

    @Test func undoLastAction関数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("func undoLastAction()"))
    }

    @Test func undoLastActionがundoStackからポップする() throws {
        let content = try editorContent
        let range = try #require(content.range(of: "func undoLastAction()"))
        let saveBoardRange = try #require(content[range.lowerBound...].range(of: "saveBoard()"))
        let body = String(content[range.lowerBound..<saveBoardRange.upperBound])
        #expect(body.contains("undoStack.popLast()"),
                "undoLastAction内でundoStack.popLast()が呼ばれていません")
    }

    // MARK: - UIボタン

    @Test func undoボタンがnavigationBarに追加されている() throws {
        let content = try editorContent
        #expect(content.contains("arrow.uturn.backward"),
                "元に戻すボタン（arrow.uturn.backward）がナビゲーションバーにありません")
    }

    @Test func undoボタンがスタック空のとき無効化される() throws {
        let content = try editorContent
        #expect(content.contains("undoStack.isEmpty"),
                "undoStack.isEmptyによる無効化がありません")
    }

    @Test func undoボタンにaccessibilityLabelが設定されている() throws {
        let content = try editorContent
        #expect(content.contains("元に戻す"),
                "元に戻すボタンのaccessibilityLabelがありません")
    }

    // MARK: - StickerItemView ジェスチャーコールバック

    @Test func onGestureStartedコールバックが定義されている() throws {
        let content = try itemViewContent
        #expect(content.contains("onGestureStarted"),
                "StickerItemViewにonGestureStartedコールバックがありません")
    }

    @Test func dragGestureでonGestureStartedが呼ばれる() throws {
        let content = try itemViewContent
        let dragRange = try #require(content.range(of: "private var dragGesture:"))
        let magnificationRange = try #require(content[dragRange.lowerBound...].range(of: "private var magnificationGesture:"))
        let body = String(content[dragRange.lowerBound..<magnificationRange.lowerBound])
        #expect(body.contains("onGestureStarted"),
                "dragGesture内でonGestureStartedが呼ばれていません")
    }

    @Test func magnificationGestureでonGestureStartedが呼ばれる() throws {
        let content = try itemViewContent
        let gestureRange = try #require(content.range(of: "private var magnificationGesture:"))
        let rotationRange = try #require(content[gestureRange.lowerBound...].range(of: "private var rotationGesture:"))
        let body = String(content[gestureRange.lowerBound..<rotationRange.lowerBound])
        #expect(body.contains("onGestureStarted"),
                "magnificationGesture内でonGestureStartedが呼ばれていません")
    }

    @Test func rotationGestureでonGestureStartedが呼ばれる() throws {
        let content = try itemViewContent
        let gestureRange = try #require(content.range(of: "private var rotationGesture"))
        let endRange = try #require(content[gestureRange.lowerBound...].range(of: "\n}\n"))
        let body = String(content[gestureRange.lowerBound..<endRange.upperBound])
        #expect(body.contains("onGestureStarted"),
                "rotationGesture内でonGestureStartedが呼ばれていません")
    }
}
