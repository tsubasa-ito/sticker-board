import Testing
import Foundation

/// StickerLibraryView のピッカーモードテスト
/// Issue #235: ボードエディタへのインラインライブラリ統合のための StickerLibraryView 改修
///
/// 注意: このテストはソースコードを文字列として読み込み、構造を検証します。
/// 対象コードの構造が変更された場合はテストのパターンマッチも更新してください。
struct StickerLibraryPickerModeTests {

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

    private var libraryContent: String {
        get throws {
            try readFile("StickerBoard/Views/Library/StickerLibraryView.swift")
        }
    }

    // MARK: - onStickerPicked パラメータ

    @Test func stickerLibraryView_onStickerPickedパラメータが存在する() throws {
        let content = try libraryContent
        #expect(content.contains("onStickerPicked"),
                "StickerLibraryView に onStickerPicked パラメータが存在しません")
    }

    @Test func stickerLibraryView_onStickerPickedがオプショナル型である() throws {
        let content = try libraryContent
        // onStickerPicked: ((Sticker) -> Void)? の形式で定義されている
        #expect(content.contains("((Sticker) -> Void)?"),
                "onStickerPicked がオプショナル型（((Sticker) -> Void)?）で定義されていません")
    }

    @Test func stickerLibraryView_onStickerPickedのデフォルト値がnilである() throws {
        let content = try libraryContent
        #expect(content.contains("onStickerPicked") && content.contains("= nil"),
                "onStickerPicked のデフォルト値が nil ではありません")
    }

    // MARK: - ピッカーモード時の動作

    @Test func stickerLibraryView_ピッカーモード時にシールタップでコールバックが呼ばれる() throws {
        let content = try libraryContent
        // onStickerPicked?(sticker) または onStickerPicked?(sticker: sticker) の呼び出しが存在する
        #expect(content.contains("onStickerPicked?("),
                "ピッカーモード時に onStickerPicked が呼び出されていません")
    }

    @Test func stickerLibraryView_ピッカーモードかどうかの判定が存在する() throws {
        let content = try libraryContent
        // onStickerPicked != nil または isPicking などの判定が存在する
        #expect(content.contains("onStickerPicked != nil") || content.contains("isPicking"),
                "ピッカーモードの判定ロジックが存在しません")
    }

    // MARK: - ナビゲーションタイトル

    @Test func stickerLibraryView_ピッカーモード時にタイトルが変わる() throws {
        let content = try libraryContent
        // ピッカーモード時に "シールを選択" というタイトルが使われる
        #expect(content.contains("シールを選択"),
                "ピッカーモード時のナビゲーションタイトル「シールを選択」が存在しません")
    }
}
