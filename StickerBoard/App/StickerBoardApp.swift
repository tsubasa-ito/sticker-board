import FirebaseCore
import FirebaseCrashlytics
import SwiftUI
import SwiftData

@main
struct StickerBoardApp: App {
    let container: ModelContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var deepLinkBoardId: UUID?

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
            container = try ModelContainer(for: Sticker.self, Board.self, Notebook.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        self.container = container

        // デフォルト手帳の作成と既存ボードの割り当て
        let context = container.mainContext
        let notebookCount = (try? context.fetchCount(FetchDescriptor<Notebook>())) ?? 0
        if notebookCount == 0 {
            // 初回: デフォルト手帳を作成
            let defaultNotebook = Notebook(title: "はじめての手帳")
            context.insert(defaultNotebook)
            // 既存ボードを全てデフォルト手帳に割り当て
            let allBoards = (try? context.fetch(FetchDescriptor<Board>())) ?? []
            for board in allBoards {
                if board.notebookIdString.isEmpty {
                    board.notebookIdString = defaultNotebook.id.uuidString
                }
            }
            // まだボードがなければデフォルトページを作成
            if allBoards.isEmpty {
                let defaultBoard = Board(title: "はじめてのページ")
                defaultBoard.notebookIdString = defaultNotebook.id.uuidString
                context.insert(defaultBoard)
            }
        } else {
            // 既存手帳あり: 未割り当てボードをエラー防止で最初の手帳に割り当て
            if let firstNotebook = try? context.fetch(FetchDescriptor<Notebook>()).first {
                let orphans = (try? context.fetch(
                    FetchDescriptor<Board>(predicate: #Predicate { $0.notebookIdString == "" })
                )) ?? []
                for board in orphans {
                    board.notebookIdString = firstNotebook.id.uuidString
                }
            }
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
            MainTabView(deepLinkBoardId: $deepLinkBoardId)
                .fullScreenCover(isPresented: Binding(
                    get: { !hasCompletedOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
                .onOpenURL { url in
                    deepLinkBoardId = WidgetDataSyncService.parseBoardId(from: url)
                }
        }
        .modelContainer(container)
    }
}
