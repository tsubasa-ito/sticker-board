import Testing
import Foundation

/// Firebase Crashlytics の導入設定を検証する構造テスト
/// Issue #134: クラッシュ検知の仕組みを導入する
///
/// 注意: このテストはソースコードを文字列として読み込み、正規表現で解析する構造検証テストです。
/// ファイルパスが変更された場合はテスト内のパスを更新してください。
struct FirebaseCrashlyticsSetupTests {

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

    // MARK: - StickerBoardApp の初期化設定

    @Test func stickerBoardAppがFirebaseCrashlyticsをimportしている() throws {
        let content = try readFile("StickerBoard/App/StickerBoardApp.swift")
        #expect(
            content.contains("import FirebaseCrashlytics"),
            "StickerBoardApp.swift に 'import FirebaseCrashlytics' が必要です"
        )
    }

    @Test func stickerBoardAppのinitでFirebaseAppConfigureが呼ばれている() throws {
        let content = try readFile("StickerBoard/App/StickerBoardApp.swift")
        #expect(
            content.contains("FirebaseApp.configure()"),
            "StickerBoardApp.init() 内で 'FirebaseApp.configure()' を呼び出す必要があります"
        )
    }

    // MARK: - project.yml の依存関係

    @Test func projectYmlにFirebaseCrashlyticsパッケージが定義されている() throws {
        let content = try readFile("project.yml")
        #expect(
            content.contains("FirebaseCrashlytics"),
            "project.yml に FirebaseCrashlytics の SPM 依存関係が必要です"
        )
    }

    @Test func projectYmlにFirebase iOS SDKのSPMパッケージURLが含まれている() throws {
        let content = try readFile("project.yml")
        #expect(
            content.contains("firebase-ios-sdk"),
            "project.yml に Firebase iOS SDK の SPM URL (firebase-ios-sdk) が必要です"
        )
    }

    @Test func projectYmlにdSYMアップロードビルドフェーズが含まれている() throws {
        let content = try readFile("project.yml")
        #expect(
            content.contains("postBuildScripts"),
            "project.yml に postBuildScripts キーが必要です（XcodeGen のスクリプトフェーズ定義）"
        )
        #expect(
            content.contains("Crashlytics"),
            "project.yml に Crashlytics dSYM アップロードスクリプトが必要です"
        )
    }

    // MARK: - Privacy Manifest

    @Test func privacyManifestが存在する() throws {
        let url = projectRootURL.appendingPathComponent("StickerBoard/PrivacyInfo.xcprivacy")
        #expect(
            FileManager.default.fileExists(atPath: url.path),
            "StickerBoard/PrivacyInfo.xcprivacy が存在する必要があります"
        )
    }

    @Test func privacyManifestにNSPrivacyCollectedDataTypesが含まれている() throws {
        let content = try readFile("StickerBoard/PrivacyInfo.xcprivacy")
        #expect(
            content.contains("NSPrivacyCollectedDataTypes"),
            "PrivacyInfo.xcprivacy に NSPrivacyCollectedDataTypes の申告が必要です"
        )
    }
}
