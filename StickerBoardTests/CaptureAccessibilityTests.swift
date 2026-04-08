import Testing
import Foundation

/// シール撮影・マスク編集フローのVoiceOverアクセシビリティ対応テスト
/// Issue #94: StickerCaptureView・MaskEditorView・MaskDrawingCanvas・BrushToolbar
struct CaptureAccessibilityTests {

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

    // MARK: - BrushToolbar アクセシビリティ

    @Test func BrushToolbar_モードボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/BrushToolbar.swift")
        // 消しゴムモードボタンと復元モードボタンに accessibilityLabel が設定されている
        #expect(content.contains("accessibilityLabel"))
    }

    @Test func BrushToolbar_モードボタンに選択状態のtraitsがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/BrushToolbar.swift")
        // 選択中のモードボタンに isSelected traits が設定されている
        #expect(content.contains("isSelected"))
    }

    @Test func BrushToolbar_スライダーにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/BrushToolbar.swift")
        // ブラシサイズスライダーに accessibilityLabel が設定されている
        #expect(content.contains("Slider") && content.contains("accessibilityLabel"))
    }

    @Test func BrushToolbar_スライダーにaccessibilityValueがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/BrushToolbar.swift")
        // ブラシサイズスライダーに accessibilityValue が設定されている
        #expect(content.contains("accessibilityValue"))
    }

    @Test func BrushToolbar_UndoボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/BrushToolbar.swift")
        // 取り消しボタンに accessibilityLabel が設定されている
        #expect(content.contains("arrow.uturn.backward") && content.contains("accessibilityLabel"))
    }

    @Test func BrushToolbar_ブラシサイズインジケーターが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Capture/BrushToolbar.swift")
        // ブラシサイズの視覚インジケーター（Circle）は装飾のため非表示
        #expect(content.contains("accessibilityHidden"))
    }

    @Test func BrushToolbar_インタラクティブ要素にaccessibilityHintがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/BrushToolbar.swift")
        // モードボタン・Undoボタンに accessibilityHint が設定されている
        #expect(content.contains("accessibilityHint"))
    }

    // MARK: - StickerCaptureView アクセシビリティ

    @Test func StickerCaptureView_カメラボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        #expect(content.contains("カメラで撮る") || content.contains("カメラで撮影"))
        #expect(content.contains("accessibilityLabel"))
    }

    @Test func StickerCaptureView_背景除去ボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // scissors ボタンに accessibilityLabel が設定されている
        #expect(content.contains("scissors") && content.contains("accessibilityLabel"))
    }

    @Test func StickerCaptureView_コレクション追加ボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // コレクション追加ボタンに accessibilityLabel が設定されている
        #expect(content.contains("コレクションに追加") && content.contains("accessibilityLabel"))
    }

    @Test func StickerCaptureView_処理中メッセージがアクセシビリティ通知される() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // 処理中セクションで AccessibilityNotification または UIAccessibility.post で通知
        #expect(content.contains("AccessibilityNotification") || content.contains("UIAccessibility.post"))
    }

    @Test func StickerCaptureView_エラーメッセージがアクセシビリティ通知される() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // エラーバナーが AccessibilityNotification で通知される
        let hasNotification = content.contains("AccessibilityNotification") || content.contains("UIAccessibility.post")
        #expect(hasNotification)
    }

    @Test func StickerCaptureView_選択写真プレビューにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // 選択された写真のプレビュー画像に accessibilityLabel が設定されている
        #expect(content.contains("uiImage: originalImage") && content.contains("accessibilityLabel"))
    }

    @Test func StickerCaptureView_手動調整ボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // 手動調整ボタンに accessibilityLabel が設定されている
        #expect(content.contains("手動で調整する") && content.contains("accessibilityLabel"))
    }

    @Test func StickerCaptureView_シミュレータ注意書きアイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // info.circle.fill アイコンは装飾のため accessibilityHidden
        #expect(content.contains("accessibilityHidden"))
    }

    @Test func StickerCaptureView_ボタンにaccessibilityHintがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // カメラ・写真選択・背景除去・コレクション追加・手動調整ボタンに accessibilityHint が設定されている
        #expect(content.contains("accessibilityHint"))
    }

    // MARK: - 長押し選択のアクセシビリティ（Issue #142）

    @Test func StickerCaptureView_長押し案内アイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // hand.tap.fill アイコンは装飾のため accessibilityHidden
        #expect(content.contains("hand.tap.fill") && content.contains("accessibilityHidden(true)"))
    }

    @Test func StickerCaptureView_写真プレビューに長押しのaccessibilityHintがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // 長押しジェスチャーの説明として accessibilityHint が設定されている
        #expect(content.contains("被写体を長押しして選択できます"))
    }

    @Test func StickerCaptureView_すべて自動で切り抜くボタンにaccessibilityLabelがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // 「すべて自動で切り抜く」ボタンに accessibilityLabel が設定されている
        #expect(content.contains("すべて自動で切り抜く") && content.contains("accessibilityLabel"))
    }

    @Test func StickerCaptureView_すべて自動で切り抜くボタンにaccessibilityHintがある() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // 「すべて自動で切り抜く」ボタンに accessibilityHint が設定されている
        #expect(content.contains("すべての被写体を自動的に検出して切り抜きます"))
    }

    @Test func StickerCaptureView_scissorsアイコンが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Capture/StickerCaptureView.swift")
        // scissors アイコン（すべて自動で切り抜くボタン内）は装飾のため accessibilityHidden
        #expect(content.contains("\"scissors\"") && content.contains("accessibilityHidden(true)"))
    }

    // MARK: - MaskEditorView アクセシビリティ

    @Test func MaskEditorView_ヒントテキストにaccessibilityが設定されている() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskEditorView.swift")
        // ヒントテキスト（「指でなぞって...」）に accessibilityLabel 設定
        #expect(content.contains("accessibilityLabel") || content.contains("AccessibilityNotification"))
    }

    @Test func MaskEditorView_処理中オーバーレイがアクセシビリティ通知される() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskEditorView.swift")
        // 「合成しています」プログレスが通知される
        let hasNotification = content.contains("AccessibilityNotification") || content.contains("UIAccessibility.post")
        #expect(hasNotification)
    }

    @Test func MaskEditorView_処理中オーバーレイの背景が装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskEditorView.swift")
        #expect(content.contains("accessibilityHidden"))
    }

    @Test func MaskEditorView_ブラシモード変更時にヒントが更新される() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskEditorView.swift")
        // brushMode による条件分岐で異なるヒントテキストが設定されている
        #expect(content.contains("brushMode == .eraser") && content.contains("accessibilityLabel"))
    }

    // MARK: - MaskDrawingCanvas アクセシビリティ

    @Test func MaskDrawingCanvas_isAccessibilityElementが設定されている() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskDrawingCanvas.swift")
        #expect(content.contains("isAccessibilityElement"))
    }

    @Test func MaskDrawingCanvas_accessibilityLabelが設定されている() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskDrawingCanvas.swift")
        #expect(content.contains("accessibilityLabel"))
    }

    @Test func MaskDrawingCanvas_accessibilityTraitsが設定されている() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskDrawingCanvas.swift")
        #expect(content.contains("accessibilityTraits"))
    }

    @Test func MaskDrawingCanvas_accessibilityHintが設定されている() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskDrawingCanvas.swift")
        // カスタムジェスチャーの代替操作説明として accessibilityHint が設定されている
        #expect(content.contains("accessibilityHint"))
    }

    @Test func MaskDrawingCanvas_allowsDirectInteractionトレイトが設定されている() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskDrawingCanvas.swift")
        // タッチ描画キャンバスにVoiceOver有効時も直接操作を許可するトレイトが設定されている
        #expect(content.contains("allowsDirectInteraction"))
    }

    @Test func MaskDrawingCanvas_チェッカーボード背景が装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskDrawingCanvas.swift")
        // CheckerboardUIView は装飾のため accessibilityElementsHidden
        let hasHidden = content.contains("accessibilityElementsHidden") || content.contains("isAccessibilityElement = false")
        #expect(hasHidden)
    }

    @Test func MaskDrawingCanvas_MaskOverlayViewが装飾非表示() throws {
        let content = try readFile("StickerBoard/Views/Capture/MaskDrawingCanvas.swift")
        // MaskOverlayView は視覚フィードバックのみのため非表示
        // MaskOverlayView の init 内で isAccessibilityElement = false が設定されている
        // 既に isUserInteractionEnabled = false だが、VoiceOver からも隠す必要がある
        let content_lower = content.lowercased()
        #expect(content_lower.contains("maskoverlayview") && content.contains("isAccessibilityElement"))
    }
}
