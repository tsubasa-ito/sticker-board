import SwiftUI
import SwiftData

@main
struct StickerBoardApp: App {
    let container: ModelContainer

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
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
