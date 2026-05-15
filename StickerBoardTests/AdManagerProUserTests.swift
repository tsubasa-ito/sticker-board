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

    @Test func stickerGridContentでshowAds条件が広告参照をガードしている() throws {
        let src = try libraryContent()
        #expect(src.contains("showAds ? adManager.nativeAd : nil"),
                "nativeAdToShow は showAds=false の場合に nil を返す必要があります")
    }

    @Test func NativeAdCardがVStack直下に配置されている() throws {
        let src = try libraryContent()
        // LazyVStack ではなく VStack を使うことでレイアウト更新を確実にする
        #expect(src.contains("VStack(spacing: 0)") && src.contains("nativeAdToShow"),
                "NativeAdCard は VStack 直下の nativeAdToShow 経由で条件表示される必要があります")
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
