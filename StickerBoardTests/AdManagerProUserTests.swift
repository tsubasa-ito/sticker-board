import Testing
import Foundation

/// AdManager の Pro ユーザー広告クリア機能テスト
/// Issue #273: 有料プランのシールライブラリに広告枠の空白が残る
struct AdManagerProUserTests {

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

    private func adManagerContent() throws -> String {
        try readFile("StickerBoard/Services/AdManager.swift")
    }

    private func libraryContent() throws -> String {
        try readFile("StickerBoard/Views/Library/StickerLibraryView.swift")
    }

    // MARK: - AdManager: clearNativeAd メソッド

    @Test func AdManagerにclearNativeAdメソッドが存在する() throws {
        let src = try adManagerContent()
        #expect(src.contains("clearNativeAd"),
                "AdManager に clearNativeAd メソッドが存在しません")
    }

    @Test func clearNativeAdはnativeAdをnilにセットする() throws {
        let src = try adManagerContent()
        #expect(src.contains("clearNativeAd") && src.contains("nativeAd = nil"),
                "clearNativeAd が nativeAd = nil を実行していません")
    }

    @Test func clearNativeAdはProユーザー以外では実行されない() throws {
        let src = try adManagerContent()
        #expect(src.contains("clearNativeAd") && src.contains("isProUser"),
                "clearNativeAd に isProUser ガード条件がありません")
    }

    // MARK: - StickerLibraryView: showAds 条件によるネイティブ広告参照制御

    @Test func ProユーザーはadChunkedGridではなくシンプルグリッドが使われる() throws {
        let src = try libraryContent()
        // isProUser=true 時は adChunkedGrid ではなく LazyVGrid シンプルパスへ分岐する
        #expect(src.contains("adChunkedGrid") && src.contains("isProUser"),
                "Pro ユーザーは adChunkedGrid と別の分岐に進む必要があります")
    }

    @Test func adChunkedGridはNativeAdCardを含む() throws {
        let src = try libraryContent()
        #expect(src.contains("adChunkedGrid") && src.contains("NativeAdCard"),
                "adChunkedGrid に NativeAdCard が存在しません")
    }

    @Test func AdNativeDelegateのonReceiveがProユーザーをガードしている() throws {
        let src = try adManagerContent()
        #expect(src.contains("onReceive") && src.contains("isProUser"),
                "onReceive コールバックに isProUser ガードが存在しません")
    }

    // MARK: - StickerLibraryView: isProUser 変化時のクリア

    @Test func isProUserがtrueになった際にclearNativeAdが呼ばれる() throws {
        let src = try libraryContent()
        #expect(src.contains("clearNativeAd") && src.contains("isProUser"),
                "isProUser が true になった際に clearNativeAd が呼ばれていません")
    }
}
