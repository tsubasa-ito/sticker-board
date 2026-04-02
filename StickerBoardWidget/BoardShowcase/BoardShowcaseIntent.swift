import AppIntents
import WidgetKit

/// ウィジェットで表示するボードを選択するための AppEntity
struct BoardEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "ボード")
    static var defaultQuery = BoardEntityQuery()

    var id: String
    var title: String
    var stickerCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(stickerCount)枚のシール"
        )
    }
}

/// ボードエンティティの検索クエリ
struct BoardEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [BoardEntity] {
        let allMetadata = WidgetDataManager.loadAllMetadata()
        return identifiers.compactMap { id in
            guard let meta = allMetadata.first(where: { $0.id == id }) else { return nil }
            return BoardEntity(id: meta.id, title: meta.title, stickerCount: meta.stickerCount)
        }
    }

    func suggestedEntities() async throws -> [BoardEntity] {
        WidgetDataManager.loadAllMetadata().map { meta in
            BoardEntity(id: meta.id, title: meta.title, stickerCount: meta.stickerCount)
        }
    }

    func defaultResult() async -> BoardEntity? {
        guard let first = WidgetDataManager.loadAllMetadata().first else { return nil }
        return BoardEntity(id: first.id, title: first.title, stickerCount: first.stickerCount)
    }
}

/// ウィジェット設定用の AppIntent
struct BoardShowcaseConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "ボードを選択"
    static var description = IntentDescription("ウィジェットに表示するボードを選択します")

    @Parameter(title: "ボード")
    var board: BoardEntity?
}
