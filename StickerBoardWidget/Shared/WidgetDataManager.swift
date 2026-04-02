import UIKit
import os

/// App Group からウィジェットデータを読み込むマネージャ
enum WidgetDataManager {

    private static let logger = Logger(subsystem: "com.tebasaki.StickerBoard.Widget", category: "WidgetDataManager")

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
        guard let url = metadataURL else { return [] }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            // 初回起動時はファイルが存在しないため正常
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([SharedBoardMetadata].self, from: data)
        } catch {
            logger.error("Failed to decode board metadata: \(error.localizedDescription)")
            return []
        }
    }

    /// 指定ボードのスナップショット画像を読み込む
    static func loadSnapshot(fileName: String) -> UIImage? {
        // パストラバーサル防止
        let sanitized = (fileName as NSString).lastPathComponent
        guard let url = snapshotsURL?.appendingPathComponent(sanitized),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// 指定ボードIDのメタデータを取得する
    static func metadata(for boardId: String) -> SharedBoardMetadata? {
        loadAllMetadata().first { $0.id == boardId }
    }
}
