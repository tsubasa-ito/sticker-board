import Testing
import Foundation
@testable import StickerBoard

/// PostHog 分析導入の検証テスト
struct AnalyticsServiceTests {

    // MARK: - ヘルパー

    private func makeDefaults() -> UserDefaults {
        let suiteName = "AnalyticsServiceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private var projectRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // StickerBoardTests/
            .deletingLastPathComponent()   // project root
    }

    private func readFile(_ relativePath: String) throws -> String {
        let url = projectRootURL.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - オプトアウト設定

    @Test func 未設定時は分析が有効() {
        let defaults = makeDefaults()
        #expect(AnalyticsService.isEnabled(defaults: defaults))
    }

    @Test func 無効化すると設定が保存される() {
        let defaults = makeDefaults()
        AnalyticsService.setEnabled(false, defaults: defaults)
        #expect(!AnalyticsService.isEnabled(defaults: defaults))
    }

    @Test func 再度有効化すると設定が保存される() {
        let defaults = makeDefaults()
        AnalyticsService.setEnabled(false, defaults: defaults)
        AnalyticsService.setEnabled(true, defaults: defaults)
        #expect(AnalyticsService.isEnabled(defaults: defaults))
    }

    @Test func テスト実行中は実データを送信しない() {
        #expect(AnalyticsService.isRunningTests)
    }

    // MARK: - イベント定義

    @Test func イベント名はスネークケース() {
        let pattern = /^[a-z]+(_[a-z]+)*$/
        for event in AnalyticsEvent.allCases {
            #expect(event.rawValue.wholeMatch(of: pattern) != nil, "\(event.rawValue) はスネークケースではありません")
        }
    }

    @Test func イベント名が重複していない() {
        let names = AnalyticsEvent.allCases.map(\.rawValue)
        #expect(Set(names).count == names.count)
    }

    // MARK: - 導入設定（構造テスト）

    @Test func 起動時にAnalyticsServiceが初期化される() throws {
        let content = try readFile("StickerBoard/App/StickerBoardApp.swift")
        #expect(content.contains("AnalyticsService.setup()"))
    }

    @Test func projectYmlにPostHogパッケージが定義されている() throws {
        let content = try readFile("project.yml")
        #expect(content.contains("https://github.com/PostHog/posthog-ios"))
        #expect(content.contains("product: PostHog"))
    }

    @Test func SwiftUIのリプレイのためscreenshotModeが有効() throws {
        let content = try readFile("StickerBoard/Services/AnalyticsService.swift")
        #expect(content.contains("sessionReplayConfig.screenshotMode = true"))
    }

    @Test func 元写真を表示する画面はリプレイでマスクされる() throws {
        for path in [
            "StickerBoard/Views/Capture/StickerCaptureView.swift",
            "StickerBoard/Views/Capture/MaskEditorView.swift",
            "StickerBoard/Views/Board/BoardEditorView.swift",
            "StickerBoard/Views/Board/BackgroundPatternPickerView.swift",
            "StickerBoard/Views/Home/HomeView.swift",
        ] {
            let content = try readFile(path)
            #expect(content.contains(".postHogMask("), "\(path) に postHogMask() が必要です")
        }
    }

    @Test func ペイウォールは表示元を指定して表示される() throws {
        for path in [
            "StickerBoard/Views/Capture/StickerCaptureView.swift",
            "StickerBoard/Views/Capture/MultiStickerSelectionView.swift",
            "StickerBoard/Views/Home/HomeView.swift",
            "StickerBoard/Views/Board/BoardListView.swift",
            "StickerBoard/Views/Board/BackgroundPatternPickerView.swift",
            "StickerBoard/Views/Board/BoardEditorView.swift",
        ] {
            let content = try readFile(path)
            #expect(!content.contains("PaywallView()"), "\(path) で PaywallView(source:) を使用してください")
        }
    }

    @Test func PrivacyManifestに分析目的のデータ収集が申告されている() throws {
        let content = try readFile("StickerBoard/PrivacyInfo.xcprivacy")
        #expect(content.contains("NSPrivacyCollectedDataTypeProductInteraction"))
        #expect(content.contains("NSPrivacyCollectedDataTypePurposeAnalytics"))
    }

    // MARK: - ローカライズ

    private var enBundle: Bundle? {
        Bundle.main.path(forResource: "en", ofType: "lproj").flatMap { Bundle(path: $0) }
    }

    @Test func 利用状況データの送信が英訳されている() throws {
        let bundle = try #require(enBundle)
        #expect(String(localized: "利用状況データの送信", bundle: bundle) == "Share Usage Data")
    }
}
