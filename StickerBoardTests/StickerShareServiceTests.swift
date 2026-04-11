import Testing
import Foundation

/// StickerShareService のテスト
/// Issue #202: シール単体の画像ダウンロード・共有機能
///
/// 注意: このテストはソースコードを文字列として読み込み、パターンで構造を検証します。
/// 対象ソースの構造が変更された場合はテストのパターンを実態に合わせて更新してください。
struct StickerShareServiceTests {

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
        get throws { try readFile("StickerBoard/Services/StickerShareService.swift") }
    }

    private var libraryViewContent: String {
        get throws { try readFile("StickerBoard/Views/Library/StickerLibraryView.swift") }
    }

    // MARK: - StickerShareService の構造

    @Test func StickerShareServiceが存在する() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("enum StickerShareService"),
            "StickerShareService が定義されていません"
        )
    }

    @Test func StickerShareService_MainActorで動作する() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("@MainActor"),
            "StickerShareService に @MainActor がありません"
        )
    }

    @Test func share関数が存在する() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("static func share("),
            "share() 関数が定義されていません"
        )
    }

    @Test func saveToPhotos関数が存在する() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("static func saveToPhotos("),
            "saveToPhotos() 関数が定義されていません"
        )
    }

    @Test func saveToPhotos_asyncで実装されている() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("func saveToPhotos(") && content.contains("async"),
            "saveToPhotos() が async になっていません"
        )
    }

    @Test func saveToPhotos_PHPhotoLibraryを使用する() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("PHPhotoLibrary"),
            "saveToPhotos() が PHPhotoLibrary を使用していません"
        )
    }

    @Test func saveToPhotos_権限チェックを行う() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("requestAuthorization"),
            "saveToPhotos() が requestAuthorization による権限チェックをしていません"
        )
    }

    @Test func presentShareSheet_UIActivityViewControllerを使用する() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("UIActivityViewController"),
            "share() が UIActivityViewController を使用していません"
        )
    }

    @Test func share_ImageStorageから画像を読み込む() throws {
        let content = try shareServiceContent
        #expect(
            content.contains("ImageStorage"),
            "share() が ImageStorage を使用していません"
        )
    }

    // MARK: - StickerLibraryView の修正

    @Test func ライブラリのコンテキストメニューに共有ボタンがある() throws {
        let content = try libraryViewContent
        #expect(
            content.contains("StickerShareService.share"),
            "StickerLibraryView のコンテキストメニューに共有ボタンがありません"
        )
    }

    @Test func ライブラリのコンテキストメニューに保存ボタンがある() throws {
        let content = try libraryViewContent
        #expect(
            content.contains("StickerShareService.saveToPhotos") ||
            content.contains("saveToPhotos"),
            "StickerLibraryView のコンテキストメニューに写真保存ボタンがありません"
        )
    }

    @Test func プレビューオーバーレイにonShareコールバックがある() throws {
        let content = try libraryViewContent
        #expect(
            content.contains("onShare"),
            "StickerPreviewOverlay に onShare コールバックがありません"
        )
    }

    @Test func プレビューオーバーレイにonSaveToPhotosコールバックがある() throws {
        let content = try libraryViewContent
        #expect(
            content.contains("onSaveToPhotos"),
            "StickerPreviewOverlay に onSaveToPhotos コールバックがありません"
        )
    }
}
