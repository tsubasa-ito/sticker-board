import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct BoardShowcaseEntry: TimelineEntry {
    let date: Date
    let boardId: String?
    let boardTitle: String
    let stickerCount: Int
    let snapshotImage: UIImage?
}

// MARK: - Timeline Provider

struct BoardShowcaseProvider: AppIntentTimelineProvider {
    typealias Entry = BoardShowcaseEntry
    typealias Intent = BoardShowcaseConfigIntent

    func placeholder(in context: Context) -> BoardShowcaseEntry {
        BoardShowcaseEntry(
            date: Date(),
            boardId: nil,
            boardTitle: "シールボード",
            stickerCount: 0,
            snapshotImage: nil
        )
    }

    func snapshot(for configuration: BoardShowcaseConfigIntent, in context: Context) async -> BoardShowcaseEntry {
        makeEntry(for: configuration)
    }

    func timeline(for configuration: BoardShowcaseConfigIntent, in context: Context) async -> Timeline<BoardShowcaseEntry> {
        let entry = makeEntry(for: configuration)
        // ウィジェットはアプリ側から WidgetCenter.reloadTimelines で更新されるため、
        // タイムラインポリシーは .never を使用
        return Timeline(entries: [entry], policy: .never)
    }

    private func makeEntry(for configuration: BoardShowcaseConfigIntent) -> BoardShowcaseEntry {
        guard let board = configuration.board else {
            // ボード未選択時: 最初のボードをデフォルト表示
            if let first = WidgetDataManager.loadAllMetadata().first {
                let image = WidgetDataManager.loadSnapshot(fileName: first.snapshotFileName)
                return BoardShowcaseEntry(
                    date: Date(),
                    boardId: first.id,
                    boardTitle: first.title,
                    stickerCount: first.stickerCount,
                    snapshotImage: image
                )
            }
            return BoardShowcaseEntry(
                date: Date(),
                boardId: nil,
                boardTitle: "シールボード",
                stickerCount: 0,
                snapshotImage: nil
            )
        }

        let metadata = WidgetDataManager.metadata(for: board.id)
        let image = metadata.flatMap { WidgetDataManager.loadSnapshot(fileName: $0.snapshotFileName) }

        return BoardShowcaseEntry(
            date: Date(),
            boardId: board.id,
            boardTitle: metadata?.title ?? board.title,
            stickerCount: metadata?.stickerCount ?? board.stickerCount,
            snapshotImage: image
        )
    }
}

// MARK: - Widget エントリービュー（サイズ分岐）

struct BoardShowcaseEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: BoardShowcaseEntry

    var body: some View {
        switch widgetFamily {
        case .systemLarge:
            BoardShowcaseLargeView(entry: entry)
        default:
            BoardShowcaseMediumView(entry: entry)
        }
    }
}

// MARK: - Widget 定義

struct BoardShowcaseWidget: Widget {
    let kind = "BoardShowcaseWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: BoardShowcaseConfigIntent.self,
            provider: BoardShowcaseProvider()
        ) { entry in
            BoardShowcaseEntryView(entry: entry)
                .widgetURL(widgetURL(for: entry))
                .containerBackground(for: .widget) {
                    Color(hex: 0xFAF0DE)
                }
        }
        .configurationDisplayName("ボードショーケース")
        .description("お気に入りのシールボードをホーム画面に飾ろう")
        .supportedFamilies([.systemMedium, .systemLarge])
    }

    private func widgetURL(for entry: BoardShowcaseEntry) -> URL? {
        guard let boardId = entry.boardId else { return nil }
        return URL(string: "stickerboard://board/\(boardId)")
    }
}
