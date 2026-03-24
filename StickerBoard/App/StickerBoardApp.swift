import SwiftUI
import SwiftData

@main
struct StickerBoardApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [Sticker.self, Board.self])
    }
}
