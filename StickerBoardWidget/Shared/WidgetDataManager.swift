import UIKit

/// App Group からウィジェットデータを読み込むマネージャ
enum WidgetDataManager {

    // MARK: - ディレクトリ

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedWidgetConstants.appGroupID)
    }

    private static var widgetDataURL: URL? {
        containerURL?.appendingPathComponent(SharedWidgetConstants.widgetDataDirectory, isDirectory: true)
    }

    private static var snapshotsURL: URL? {
        widgetDataURL?.appendingPathComponent(SharedWidgetConstants.snapshotsDirectory, isDirectory: true)
    }

    private static var metadataURL: URL? {
        widgetDataURL?.appendingPathComponent(SharedWidgetConstants.metadataFileName)
    }

    // MARK: - データ読み込み

    /// 全ボードのメタデータを読み込む
    static func loadAllMetadata() -> [SharedBoardMetadata] {
        guard let url = metadataURL,
              let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([SharedBoardMetadata].self, from: data)) ?? []
    }

    /// 指定ボードのスナップショット画像を読み込む
    static func loadSnapshot(fileName: String) -> UIImage? {
        guard let url = snapshotsURL?.appendingPathComponent(fileName),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// 指定ボードIDのメタデータを取得する
    static func metadata(for boardId: String) -> SharedBoardMetadata? {
        loadAllMetadata().first { $0.id == boardId }
    }
}
