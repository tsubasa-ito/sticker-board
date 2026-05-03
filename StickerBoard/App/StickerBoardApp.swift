import FirebaseCore
import FirebaseCrashlytics
import GoogleMobileAds
import SwiftUI
import SwiftData
import UserNotifications

// MARK: - 通知デリゲート（通知タップ → ディープリンク変換）

extension Notification.Name {
    static let openStickerDeepLink = Notification.Name("openStickerDeepLink")
}

final class NotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        guard let idString = response.notification.request.content.userInfo["stickerId"] as? String,
              let uuid = UUID(uuidString: idString) else { return }
        await MainActor.run {
            NotificationCenter.default.post(name: .openStickerDeepLink, object: uuid)
        }
    }
}

@main
struct StickerBoardApp: App {
    @UIApplicationDelegateAdaptor(NotificationDelegate.self) private var notificationDelegate
    let container: ModelContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var deepLinkBoardId: UUID?
    @State private var deepLinkStickerId: UUID?

    init() {
        // Firebase の初期化（Crashlytics によるクラッシュ検知）
        // GoogleService-Info.plist が未配置の場合はスキップ（開発環境対応）
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
            #if DEBUG
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
            #endif
        }

        // Google Mobile Ads SDK 初期化は ATT 許可後に AdManager.preloadAll() から呼ぶ

        let container: ModelContainer
        do {
            container = try ModelContainer(for: Sticker.self, Board.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        self.container = container

        // 初回起動時にデフォルトボードを作成
        let context = container.mainContext
        let boardCount = (try? context.fetchCount(FetchDescriptor<Board>())) ?? 0
        if boardCount == 0 {
            let defaultBoard = Board(title: "はじめてのボード")
            context.insert(defaultBoard)
        }

        // グローバルNavBar外観設定
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        navBarAppearance.backgroundColor = UIColor(AppTheme.backgroundPrimary)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.textPrimary)
        ]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(AppTheme.accent)

        // サブスクリプションマネージャーの早期初期化
        _ = SubscriptionManager.shared

        // アプリ起動回数カウント
        let launchCount = UserDefaults.standard.integer(forKey: "appLaunchCount") + 1
        UserDefaults.standard.set(launchCount, forKey: "appLaunchCount")
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(deepLinkBoardId: $deepLinkBoardId, deepLinkStickerId: $deepLinkStickerId)
                .fullScreenCover(isPresented: Binding(
                    get: { !hasCompletedOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView {
                        hasCompletedOnboarding = true
                        Task {
                            await UnplacedStickerReminderService.shared.requestAuthorization()
                            // オンボーディング完了後に ATT 許可を要求
                            try? await Task.sleep(for: .seconds(1))
                            await AdManager.shared.requestTrackingPermissionIfNeeded()
                            AdManager.shared.preloadAll()
                        }
                    }
                }
                .onOpenURL { url in
                    if let boardId = WidgetDataSyncService.parseBoardId(from: url) {
                        deepLinkBoardId = boardId
                    } else if let stickerId = UnplacedStickerReminderService.parseStickerId(from: url) {
                        deepLinkStickerId = stickerId
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .openStickerDeepLink)) { notification in
                    deepLinkStickerId = notification.object as? UUID
                }
                .task {
                    await UnplacedStickerReminderService.shared.rescheduleIfNeeded(
                        context: container.mainContext
                    )
                    // 起動時にATT確認（オンボーディング済みの場合）と広告プリロード
                    if hasCompletedOnboarding {
                        await AdManager.shared.requestTrackingPermissionIfNeeded()
                    }
                    AdManager.shared.preloadAll()
                }
        }
        .modelContainer(container)
    }
}
