import Testing
import Foundation

/// オンボーディング・プレビュー画面のVoiceOverアクセシビリティ対応テスト
/// Issue #99: OnboardingView, OnboardingPageView, OnboardingPageIndicator, StickerPreviewView, CaptureGuideTipsView
struct OnboardingAccessibilityTests {

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

    // MARK: - OnboardingView

    @Test func スキップボタンにaccessibilityLabelがある() throws {
        let src = try readFile("StickerBoard/Views/Onboarding/OnboardingView.swift")
        #expect(src.contains("スキップ") && src.contains("accessibilityLabel"))
    }

    @Test func 次へボタンにaccessibilityLabelがある() throws {
        let src = try readFile("StickerBoard/Views/Onboarding/OnboardingView.swift")
        #expect(src.contains("次へ") && src.contains("accessibilityLabel"))
    }

    // MARK: - OnboardingPageView

    @Test func メインアイコンが装飾非表示() throws {
        let src = try readFile("StickerBoard/Views/Onboarding/OnboardingPageView.swift")
        // page.icon の Image は装飾（タイトル・説明で内容が伝わる）
        #expect(src.contains("page.icon") && src.contains("accessibilityHidden"))
    }

    @Test func セカンダリアイコンが装飾非表示() throws {
        let src = try readFile("StickerBoard/Views/Onboarding/OnboardingPageView.swift")
        // secondaryIcon の Image は装飾
        #expect(src.contains("secondaryIcon") && src.contains("accessibilityHidden"))
    }

    @Test func 背景円が装飾非表示() throws {
        let src = try readFile("StickerBoard/Views/Onboarding/OnboardingPageView.swift")
        // iconArea 内の背景 Circle は装飾
        #expect(src.contains("iconArea") && src.contains("accessibilityHidden"))
    }

    // MARK: - OnboardingPageIndicator

    @Test func ページインジケーターがaccessibilityElementでグループ化() throws {
        let src = try readFile("StickerBoard/Views/Onboarding/OnboardingPageIndicator.swift")
        #expect(src.contains("accessibilityElement"))
    }

    @Test func ページインジケーターにaccessibilityLabelがある() throws {
        let src = try readFile("StickerBoard/Views/Onboarding/OnboardingPageIndicator.swift")
        // 「ページ N / M」のようなラベルが設定されている
        #expect(src.contains("accessibilityLabel"))
    }

    @Test func ページインジケーターにaccessibilityValueがある() throws {
        let src = try readFile("StickerBoard/Views/Onboarding/OnboardingPageIndicator.swift")
        #expect(src.contains("accessibilityValue"))
    }

    // MARK: - StickerPreviewView

    @Test func プレビュー画像にaccessibilityLabelがある() throws {
        let src = try readFile("StickerBoard/Views/Capture/StickerPreviewView.swift")
        #expect(src.contains("uiImage: image") && src.contains("accessibilityLabel"))
    }

    @Test func チェックマークアイコンが装飾非表示() throws {
        let src = try readFile("StickerBoard/Views/Capture/StickerPreviewView.swift")
        #expect(src.contains("checkmark.seal") && src.contains("accessibilityHidden"))
    }

    @Test func チェッカーボード背景が装飾非表示() throws {
        let src = try readFile("StickerBoard/Views/Capture/StickerPreviewView.swift")
        #expect(src.contains("CheckerboardBackground") && src.contains("accessibilityHidden"))
    }

    // MARK: - CaptureGuideTipsView

    @Test func 折りたたみボタンにaccessibilityLabelがある() throws {
        let src = try readFile("StickerBoard/Views/Capture/CaptureGuideTipsView.swift")
        #expect(src.contains("きれいに切り抜くコツ") && src.contains("accessibilityLabel"))
    }

    @Test func 折りたたみ状態がaccessibilityValueで通知される() throws {
        let src = try readFile("StickerBoard/Views/Capture/CaptureGuideTipsView.swift")
        #expect(src.contains("isCollapsed") && src.contains("accessibilityValue"))
    }

    @Test func シェブロンアイコンが装飾非表示() throws {
        let src = try readFile("StickerBoard/Views/Capture/CaptureGuideTipsView.swift")
        #expect(src.contains("chevron") && src.contains("accessibilityHidden"))
    }

    @Test func ヒントアイコンが装飾非表示() throws {
        let src = try readFile("StickerBoard/Views/Capture/CaptureGuideTipsView.swift")
        #expect(src.contains("tip.icon") && src.contains("accessibilityHidden"))
    }

    @Test func 電球アイコンが装飾非表示() throws {
        let src = try readFile("StickerBoard/Views/Capture/CaptureGuideTipsView.swift")
        #expect(src.contains("lightbulb") && src.contains("accessibilityHidden"))
    }
}
