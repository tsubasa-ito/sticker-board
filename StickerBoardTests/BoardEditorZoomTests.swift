import Testing
import Foundation

/// ボード編集画面のキャンバスズーム機能テスト
/// Issue #214: シールボード編集を拡大、縮小対応するようにする
///
/// 注意: このテストはソースコードを文字列として読み込み、パターンマッチで構造を検証します。
/// BoardEditorView.swift / StickerItemView.swift の構造が変更された場合、
/// テストのパターンマッチを実態に合わせて更新してください。
struct BoardEditorZoomTests {

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

    private var stickerItemContent: String {
        get throws { try readFile("StickerBoard/Views/Board/StickerItemView.swift") }
    }

    // MARK: - 状態変数

    @Test func isZoomMode状態変数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("isZoomMode"),
                "isZoomMode状態変数が定義されていません")
    }

    @Test func canvasScale状態変数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("canvasScale"),
                "canvasScale状態変数が定義されていません")
    }

    @Test func canvasOffset状態変数が定義されている() throws {
        let content = try editorContent
        #expect(content.contains("canvasOffset"),
                "canvasOffset状態変数が定義されていません")
    }

    @Test func liveZoomScaleのGestureStateが定義されている() throws {
        let content = try editorContent
        #expect(content.contains("liveZoomScale"),
                "@GestureState liveZoomScaleが定義されていません")
    }

    @Test func livePanOffsetのGestureStateが定義されている() throws {
        let content = try editorContent
        #expect(content.contains("livePanOffset"),
                "@GestureState livePanOffsetが定義されていません")
    }

    // MARK: - zoomedCanvasArea

    @Test func zoomedCanvasAreaが定義されている() throws {
        let content = try editorContent
        #expect(content.contains("zoomedCanvasArea"),
                "zoomedCanvasArea Viewが定義されていません")
    }

    @Test func zoomedCanvasAreaにscaleEffectが適用されている() throws {
        let content = try editorContent
        let range = try #require(content.range(of: "var zoomedCanvasArea"))
        let fromZoomed = String(content[range.lowerBound...])
        // zoomedCanvasArea の定義ブロックを抽出
        var braceCount = 0
        var endIndex = fromZoomed.startIndex
        var started = false
        for idx in fromZoomed.indices {
            if fromZoomed[idx] == "{" {
                braceCount += 1
                started = true
            } else if fromZoomed[idx] == "}" {
                braceCount -= 1
            }
            endIndex = idx
            if started && braceCount == 0 { break }
        }
        let body = String(fromZoomed[fromZoomed.startIndex...endIndex])
        #expect(body.contains("scaleEffect"),
                "zoomedCanvasAreaにscaleEffectが適用されていません")
    }

    @Test func zoomedCanvasAreaにclippedが適用されている() throws {
        let content = try editorContent
        let range = try #require(content.range(of: "var zoomedCanvasArea"))
        let fromZoomed = String(content[range.lowerBound...])
        var braceCount = 0
        var endIndex = fromZoomed.startIndex
        var started = false
        for idx in fromZoomed.indices {
            if fromZoomed[idx] == "{" {
                braceCount += 1
                started = true
            } else if fromZoomed[idx] == "}" {
                braceCount -= 1
            }
            endIndex = idx
            if started && braceCount == 0 { break }
        }
        let body = String(fromZoomed[fromZoomed.startIndex...endIndex])
        #expect(body.contains(".clipped()"),
                "zoomedCanvasAreaに.clipped()が適用されていません")
    }

    // MARK: - ズームジェスチャー設定

    @Test func ズームモードOFF時にジェスチャーが無効化される() throws {
        let content = try editorContent
        #expect(content.contains("including: .none"),
                "ズームモードOFF時のジェスチャー無効化（including: .none）が実装されていません")
    }

    @Test func ズーム範囲の最小値が設定されている() throws {
        let content = try editorContent
        #expect(content.contains("0.3"),
                "ズーム最小倍率0.3xが定義されていません")
    }

    @Test func ズーム範囲の最大値が設定されている() throws {
        let content = try editorContent
        #expect(content.contains("5.0"),
                "ズーム最大倍率5.0xが定義されていません")
    }

    // MARK: - ツールバーボタン

    @Test func ツールバーにmagnifyingglassアイコンが存在する() throws {
        let content = try editorContent
        #expect(content.contains("magnifyingglass"),
                "ズームボタン（magnifyingglassアイコン）がツールバーに存在しません")
    }

    @Test func isZoomModeのトグルが実装されている() throws {
        let content = try editorContent
        #expect(content.contains("isZoomMode.toggle()"),
                "isZoomMode.toggle()が実装されていません")
    }

    @Test func ズームモード切替時にselectedPlacementIdがリセットされる() throws {
        let content = try editorContent
        // ズームボタン付近に selectedPlacementId = nil が存在すること
        let range = try #require(content.range(of: "isZoomMode.toggle()"))
        // toggle() の前後50行程度のコンテキストに selectedPlacementId = nil があること
        let start = content.index(range.lowerBound, offsetBy: -500, limitedBy: content.startIndex) ?? content.startIndex
        let end = content.index(range.upperBound, offsetBy: 500, limitedBy: content.endIndex) ?? content.endIndex
        let context = String(content[start..<end])
        #expect(context.contains("selectedPlacementId = nil"),
                "ズームモード切替時にselectedPlacementIdがnilになっていません")
    }

    // MARK: - ズームインジケーター & リセットボタン

    @Test func ズームモードインジケーターテキストが存在する() throws {
        let content = try editorContent
        #expect(content.contains("ズームモード"),
                "ズームモードインジケーターのテキストが実装されていません")
    }

    @Test func リセットボタンが存在する() throws {
        let content = try editorContent
        #expect(content.contains("リセット"),
                "リセットボタンが実装されていません")
    }

    @Test func リセット時にcanvasScaleが1_0に戻る() throws {
        let content = try editorContent
        #expect(content.contains("canvasScale = 1.0"),
                "リセット時にcanvasScale = 1.0が設定されていません")
    }

    @Test func リセット時にcanvasOffsetがzeroに戻る() throws {
        let content = try editorContent
        #expect(content.contains("canvasOffset = .zero"),
                "リセット時にcanvasOffset = .zeroが設定されていません")
    }

    // MARK: - シールのヒットテスト制御

    @Test func ズームモード中はシールのhitTestingが無効化される() throws {
        let content = try editorContent
        #expect(content.contains("allowsHitTesting"),
                ".allowsHitTesting(!isZoomMode)が実装されていません")
    }

    // MARK: - StickerItemView

    @Test func StickerItemViewにcanvasScaleパラメータが追加されている() throws {
        let content = try stickerItemContent
        #expect(content.contains("canvasScale"),
                "StickerItemViewにcanvasScaleパラメータが追加されていません")
    }

    @Test func ドラッグ座標がcanvasScaleで補正されている() throws {
        let content = try stickerItemContent
        let range = try #require(content.range(of: "private var dragGesture:"))
        let fromDrag = String(content[range.lowerBound...])
        var braceCount = 0
        var endIndex = fromDrag.startIndex
        var started = false
        for idx in fromDrag.indices {
            if fromDrag[idx] == "{" {
                braceCount += 1
                started = true
            } else if fromDrag[idx] == "}" {
                braceCount -= 1
            }
            endIndex = idx
            if started && braceCount == 0 { break }
        }
        let body = String(fromDrag[fromDrag.startIndex...endIndex])
        #expect(body.contains("canvasScale"),
                "dragGesture内でドラッグ座標がcanvasScaleで補正されていません")
    }

    // MARK: - VoiceOverアクセシビリティ

    @Test func ズームモード切替にVoiceOverアナウンスが設定されている() throws {
        let content = try editorContent
        // isZoomMode.toggle() と UIAccessibility.post が両方存在すること
        #expect(content.contains("isZoomMode.toggle()") && content.contains("UIAccessibility.post"),
                "ズームモード切替のVoiceOverアナウンスが実装されていません")
    }
}
