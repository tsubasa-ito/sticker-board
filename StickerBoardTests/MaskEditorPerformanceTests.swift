import Testing
import Foundation

/// マスク手動編集画面の描画パフォーマンステスト
/// Issue #230: シールの背景除去を手動でする際のパフォーマンスアップ
///
/// ## 問題の背景
/// MaskCanvasUIView がCADisplayLinkで最大30fps制限のオーバーレイ更新を行っていたため、
/// touchesMoved から描画反映まで最大67msの遅延が発生していた。
/// また MaskOverlayView.invertMask() で毎フレーム新規 CIFilter を生成していたためコストが高かった。
///
/// ## 修正方針
/// - CADisplayLink を廃止し、touchesMoved で直接 updateOverlayFromMask() を呼び出す
/// - CIFilter をstaticプロパティにキャッシュして再生成コストを排除する
/// - coalescedTouches を利用してストロークの精度を向上させる
///
/// 注意: このテストはソースコードを文字列として読み込み、パターンマッチで構造を検証します。
/// MaskDrawingCanvas.swift のメソッド名・構造が変更された場合、
/// テストのパターンマッチを実態に合わせて更新してください。
struct MaskEditorPerformanceTests {

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

    private var canvasContent: String {
        get throws { try readFile("StickerBoard/Views/Capture/MaskDrawingCanvas.swift") }
    }

    // MARK: - CADisplayLink 廃止

    @Test func CADisplayLinkが使用されていないこと() throws {
        let content = try canvasContent
        #expect(!content.contains("CADisplayLink"),
                "CADisplayLinkはオーバーレイ更新の遅延原因です。touchesMovedで直接updateOverlayFromMask()を呼ぶ方式に変更してください")
    }

    @Test func needsOverlayUpdateフラグが存在しないこと() throws {
        let content = try canvasContent
        #expect(!content.contains("needsOverlayUpdate"),
                "needsOverlayUpdateフラグはCADisplayLink方式の残骸です。直接更新方式では不要です")
    }

    // MARK: - 直接オーバーレイ更新

    @Test func updateOverlayFromMask関数が定義されていること() throws {
        let content = try canvasContent
        #expect(content.contains("func updateOverlayFromMask()"),
                "touchesMovedから呼ぶ直接更新ヘルパー updateOverlayFromMask() が定義されていません")
    }

    @Test func touchesMovedでupdateOverlayFromMaskが呼ばれること() throws {
        let content = try canvasContent
        // touchesMoved 内の本体を抽出して確認
        let range = try #require(content.range(of: "func touchesMoved("),
                                 "touchesMoved が見つかりません")
        let fromMoved = content[range.lowerBound...]
        var braceCount = 0
        var endIndex = fromMoved.startIndex
        var started = false
        for idx in fromMoved.indices {
            if fromMoved[idx] == "{" {
                braceCount += 1
                started = true
            } else if fromMoved[idx] == "}" {
                braceCount -= 1
            }
            endIndex = idx
            if started && braceCount == 0 { break }
        }
        let body = String(fromMoved[fromMoved.startIndex...endIndex])
        #expect(body.contains("updateOverlayFromMask()"),
                "touchesMoved内でupdateOverlayFromMask()が呼ばれていません。直接更新でレイテンシを排除してください")
    }

    // MARK: - coalescedTouches によるストローク精度向上

    @Test func coalescedTouchesが使用されていること() throws {
        let content = try canvasContent
        #expect(content.contains("coalescedTouches"),
                "coalescedTouches が使用されていません。UIEvent.coalescedTouches(for:) でストロークの精度を向上させてください")
    }

    // MARK: - CIFilter キャッシュ

    @Test func invertFilterがインスタンスプロパティとしてキャッシュされていること() throws {
        let content = try canvasContent
        // CIFilter はスレッドセーフでないため static 共有は禁止。インスタンスプロパティとしてキャッシュする
        #expect(
            content.contains("let invertFilter") || content.contains("var invertFilter"),
            "MaskOverlayView.invertFilter がインスタンスプロパティとしてキャッシュされていません。毎フレームの CIFilter 生成コストを排除するためにインスタンスキャッシュが必要です"
        )
        #expect(
            !content.contains("static let invertFilter") && !content.contains("static var invertFilter"),
            "CIFilter は NSObject のミュータブルサブクラスでスレッドセーフではないため static 共有は禁止です"
        )
    }
}
