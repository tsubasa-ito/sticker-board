import FirebaseCore
import FirebaseCrashlytics
import SwiftUI
import SwiftData

@main
struct StickerBoardApp: App {
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
                .task {
                    await UnplacedStickerReminderService.shared.rescheduleIfNeeded(
                        context: container.mainContext
                    )
                }
        }
        .modelContainer(container)
    }
}
