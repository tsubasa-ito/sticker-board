import Testing
import Foundation
@testable import StickerBoard

struct AppUpdateCheckerTests {

    // MARK: - isNewerVersion

    @Test func 新しいバージョンを正しく検出する() {
        let checker = AppUpdateChecker.shared

        #expect(checker.isNewerVersion("2.0.0", than: "1.0.0") == true)
        #expect(checker.isNewerVersion("1.1.0", than: "1.0.0") == true)
        #expect(checker.isNewerVersion("1.0.1", than: "1.0.0") == true)
    }

    @Test func 同じバージョンは新しくない() {
        let checker = AppUpdateChecker.shared

        #expect(checker.isNewerVersion("1.0.0", than: "1.0.0") == false)
    }

    @Test func 古いバージョンは新しくない() {
        let checker = AppUpdateChecker.shared

        #expect(checker.isNewerVersion("1.0.0", than: "2.0.0") == false)
        #expect(checker.isNewerVersion("1.0.0", than: "1.1.0") == false)
        #expect(checker.isNewerVersion("1.0.0", than: "1.0.1") == false)
    }

    @Test func メジャーバージョンが優先される() {
        let checker = AppUpdateChecker.shared

        #expect(checker.isNewerVersion("2.0.0", than: "1.9.9") == true)
        #expect(checker.isNewerVersion("1.9.9", than: "2.0.0") == false)
    }

    @Test func 不正なバージョン文字列はfalseを返す() {
        let checker = AppUpdateChecker.shared

        #expect(checker.isNewerVersion("invalid", than: "1.0.0") == false)
        #expect(checker.isNewerVersion("1.0.0", than: "invalid") == false)
        #expect(checker.isNewerVersion("", than: "1.0.0") == false)
    }

    // MARK: - isMajorUpdate

    @Test func メジャーアップデートを正しく検出する() {
        let checker = AppUpdateChecker.shared

        #expect(checker.isMajorUpdate("2.0.0", from: "1.0.0") == true)
        #expect(checker.isMajorUpdate("3.0.0", from: "1.5.2") == true)
    }

    @Test func マイナーアップデートはメジャーではない() {
        let checker = AppUpdateChecker.shared

        #expect(checker.isMajorUpdate("1.1.0", from: "1.0.0") == false)
        #expect(checker.isMajorUpdate("1.0.1", from: "1.0.0") == false)
    }

    @Test func 同じメジャーバージョンはメジャーアップデートではない() {
        let checker = AppUpdateChecker.shared

        #expect(checker.isMajorUpdate("1.0.0", from: "1.0.0") == false)
    }

    @Test func 不正なバージョンのメジャー判定はfalse() {
        let checker = AppUpdateChecker.shared

        #expect(checker.isMajorUpdate("invalid", from: "1.0.0") == false)
        #expect(checker.isMajorUpdate("2.0.0", from: "invalid") == false)
    }

    // MARK: - shouldCheckUpdate (24時間間隔)

    @Test func 前回チェックから24時間以上経過していればtrueを返す() {
        let checker = AppUpdateChecker.shared
        let twentyFiveHoursAgo = Date().addingTimeInterval(-25 * 60 * 60).timeIntervalSince1970

        #expect(checker.shouldCheckUpdate(lastCheckDate: twentyFiveHoursAgo) == true)
    }

    @Test func 前回チェックから24時間未満ならfalseを返す() {
        let checker = AppUpdateChecker.shared
        let oneHourAgo = Date().addingTimeInterval(-1 * 60 * 60).timeIntervalSince1970

        #expect(checker.shouldCheckUpdate(lastCheckDate: oneHourAgo) == false)
    }

    @Test func 前回チェック日が0ならtrueを返す() {
        let checker = AppUpdateChecker.shared

        #expect(checker.shouldCheckUpdate(lastCheckDate: 0) == true)
    }

    // MARK: - shouldShowAlert (スキップ管理)

    @Test func スキップ済みバージョンと同じマイナーアップデートは表示しない() {
        let checker = AppUpdateChecker.shared

        #expect(checker.shouldShowAlert(
            storeVersion: "1.1.0",
            currentVersion: "1.0.0",
            skippedVersion: "1.1.0"
        ) == false)
    }

    @Test func スキップ済みと異なるバージョンは表示する() {
        let checker = AppUpdateChecker.shared

        #expect(checker.shouldShowAlert(
            storeVersion: "1.2.0",
            currentVersion: "1.0.0",
            skippedVersion: "1.1.0"
        ) == true)
    }

    @Test func メジャーアップデートはスキップ済みでも表示する() {
        let checker = AppUpdateChecker.shared

        #expect(checker.shouldShowAlert(
            storeVersion: "2.0.0",
            currentVersion: "1.0.0",
            skippedVersion: "2.0.0"
        ) == true)
    }

    @Test func 新しいバージョンがなければ表示しない() {
        let checker = AppUpdateChecker.shared

        #expect(checker.shouldShowAlert(
            storeVersion: "1.0.0",
            currentVersion: "1.0.0",
            skippedVersion: ""
        ) == false)
    }

    // MARK: - iTunes Lookup APIレスポンスパース

    @Test func 正常なAPIレスポンスをパースできる() throws {
        let json = """
        {
            "resultCount": 1,
            "results": [{
                "version": "2.0.0",
                "trackViewUrl": "https://apps.apple.com/app/id123456"
            }]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AppUpdateChecker.ITunesLookupResponse.self, from: json)
        #expect(response.resultCount == 1)
        #expect(response.results.first?.version == "2.0.0")
        #expect(response.results.first?.trackViewUrl == "https://apps.apple.com/app/id123456")
    }

    @Test func 結果が0件のAPIレスポンスをパースできる() throws {
        let json = """
        {
            "resultCount": 0,
            "results": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AppUpdateChecker.ITunesLookupResponse.self, from: json)
        #expect(response.resultCount == 0)
        #expect(response.results.isEmpty)
    }
}
