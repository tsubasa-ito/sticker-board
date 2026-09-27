import Foundation
import PostHog

/// 分析イベント名（PostHog のダッシュボード・ファネルで参照するためスネークケースで固定）
enum AnalyticsEvent: String, CaseIterable {
    case onboardingCompleted = "onboarding_completed"
    case stickerSaved = "sticker_saved"
    case boardCreated = "board_created"
    case stickerPlaced = "sticker_placed"
    case boardShared = "board_shared"
    case boardSavedToPhotos = "board_saved_to_photos"
    case paywallViewed = "paywall_viewed"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseCancelled = "purchase_cancelled"
    case purchasePending = "purchase_pending"
    case purchaseFailed = "purchase_failed"
}

/// ペイウォールの表示元（どの制限に当たって課金導線に来たかを分析するため）
enum PaywallSource: String {
    case stickerLimit = "sticker_limit"
    case boardLimit = "board_limit"
    case background = "background"
    case border = "border"
}

/// PostHog によるプロダクト分析・セッションリプレイを一元管理する
///
/// - 送信するのは匿名 ID のみ（identify しない）。ATT の許可は不要
/// - 設定画面のトグルでオプトアウト可能（`isEnabledKey` に保存）
/// - セッションリプレイのサンプリング率は PostHog のプロジェクト設定側で管理する
enum AnalyticsService {
    static let isEnabledKey = "analyticsEnabled"

    // プロジェクトトークンはクライアント埋め込み前提の公開キー
    private static let projectToken = "phc_mERNGFBSSwiYGJrpDrz25rUy97i6PfTS79RMdyUn3cJt"
    private static let host = "https://us.i.posthog.com"

    /// ユーザーが分析データの送信を許可しているか（未設定時は許可）
    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: isEnabledKey) as? Bool ?? true
    }

    /// ユニットテスト実行中はホストアプリから実データを送信しない
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// アプリ起動時に1回呼び出す（メインスレッド必須: セッションリプレイがビュー階層をスウィズルするため）
    @MainActor
    static func setup() {
        guard !isRunningTests else { return }

        let config = PostHogConfig(projectToken: projectToken, host: host)
        config.captureApplicationLifecycleEvents = true
        // SwiftUI では UIHostingController 名しか取れないため、画面名は postHogScreenView で明示する
        config.captureScreenViews = false
        config.optOut = !isEnabled()

        config.sessionReplay = true
        // SwiftUI のリプレイには screenshotMode が必須
        config.sessionReplayConfig.screenshotMode = true
        config.sessionReplayConfig.maskAllTextInputs = true
        // シール画像が主要コンテンツのため画像は表示し、元写真などは postHogMask() で個別にマスクする
        config.sessionReplayConfig.maskAllImages = false
        config.sessionReplayConfig.captureNetworkTelemetry = false

        PostHogSDK.shared.setup(config)

        #if DEBUG
        let buildConfiguration = "debug"
        #else
        let buildConfiguration = "release"
        #endif
        PostHogSDK.shared.register(["build_configuration": buildConfiguration])
    }

    static func capture(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        guard !isRunningTests else { return }
        PostHogSDK.shared.capture(event.rawValue, properties: properties)
    }

    /// 画面表示を記録する（タブ切り替えなど onAppear が発火しない画面遷移用）
    static func screen(_ name: String) {
        guard !isRunningTests else { return }
        PostHogSDK.shared.screen(name)
    }

    /// 設定画面のトグルから呼び出す
    static func setEnabled(_ enabled: Bool, defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: isEnabledKey)
        guard !isRunningTests else { return }
        if enabled {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
        }
    }

    /// Pro 状態を全イベントの共通プロパティとして登録する（無料/Pro 別のファネル比較用）
    static func updateProStatus(_ isPro: Bool) {
        guard !isRunningTests else { return }
        PostHogSDK.shared.register(["is_pro": isPro])
    }
}
