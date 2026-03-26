import SwiftUI
import SwiftData

@main
struct StickerBoardApp: App {
    let container: ModelContainer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
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
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .fullScreenCover(isPresented: Binding(
                    get: { !hasCompletedOnboarding },
                    set: { if !$0 { hasCompletedOnboarding = true } }
                )) {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
        }
        .modelContainer(container)
    }
}
