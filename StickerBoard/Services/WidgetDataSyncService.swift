import UIKit
import WidgetKit

/// メインアプリからウィジェットへのデータ同期を管理する
enum WidgetDataSyncService {

    // MARK: - App Group ディレクトリ

    /// App Group の共有コンテナURL
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedWidgetConstants.appGroupID)
    }

    /// ウィジェットデータのルートディレクトリ
    static var widgetDataURL: URL? {
        guard let container = containerURL else { return nil }
        let url = container.appendingPathComponent(SharedWidgetConstants.widgetDataDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// スナップショット画像の保存ディレクトリ
    static var snapshotsURL: URL? {
        guard let widgetData = widgetDataURL else { return nil }
        let url = widgetData.appendingPathComponent(SharedWidgetConstants.snapshotsDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// メタデータJSONのURL
    static var metadataURL: URL? {
        widgetDataURL?.appendingPathComponent(SharedWidgetConstants.metadataFileName)
    }

    // MARK: - メタデータ生成

    /// Board からウィジェット用メタデータを生成する
    static func generateMetadata(
        boardId: UUID,
        title: String,
        stickerCount: Int,
        updatedAt: Date
    ) -> SharedBoardMetadata {
        SharedBoardMetadata(
            id: boardId.uuidString,
            title: title,
            stickerCount: stickerCount,
            updatedAt: updatedAt,
            snapshotFileName: "\(boardId.uuidString).jpg"
        )
    }

    // MARK: - メタデータJSON 読み書き

    /// メタデータ配列をJSONとして書き出す
    static func writeMetadataJSON(_ metadata: [SharedBoardMetadata], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(metadata)
        try data.write(to: url, options: .atomic)
    }

    /// JSONからメタデータ配列を読み込む
    static func readMetadataJSON(from url: URL) throws -> [SharedBoardMetadata] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([SharedBoardMetadata].self, from: data)
    }

    // MARK: - スナップショット画像

    /// スナップショット画像をJPEGとして保存する
    static func saveSnapshot(_ image: UIImage, to url: URL) throws {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw WidgetSyncError.snapshotEncodingFailed
        }
        try data.write(to: url, options: .atomic)
    }

    /// スナップショット画像を削除する
    static func deleteSnapshot(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - 同期メソッド（メインアプリから呼び出す）

    /// 指定ボードのスナップショットとメタデータを同期する
    static func syncBoard(
        boardId: UUID,
        title: String,
        stickerCount: Int,
        updatedAt: Date,
        snapshotImage: UIImage,
        allBoardsMetadata: [SharedBoardMetadata]
    ) {
        guard let snapshotsDir = snapshotsURL,
              let metaURL = metadataURL else { return }

        let snapshotURL = snapshotsDir.appendingPathComponent("\(boardId.uuidString).jpg")

        do {
            try saveSnapshot(snapshotImage, to: snapshotURL)
            try writeMetadataJSON(allBoardsMetadata, to: metaURL)
            WidgetCenter.shared.reloadTimelines(ofKind: SharedWidgetConstants.widgetKind)
        } catch {
            print("[WidgetSync] Failed to sync board: \(error)")
        }
    }

    /// 全ボードのメタデータを一括同期する
    static func syncAllMetadata(_ metadata: [SharedBoardMetadata]) {
        guard let metaURL = metadataURL else { return }
        do {
            try writeMetadataJSON(metadata, to: metaURL)
            WidgetCenter.shared.reloadTimelines(ofKind: SharedWidgetConstants.widgetKind)
        } catch {
            print("[WidgetSync] Failed to sync metadata: \(error)")
        }
    }

    /// 削除されたボードのスナップショットをクリーンアップする
    static func removeBoard(boardId: UUID, remainingMetadata: [SharedBoardMetadata]) {
        guard let snapshotsDir = snapshotsURL,
              let metaURL = metadataURL else { return }

        let snapshotURL = snapshotsDir.appendingPathComponent("\(boardId.uuidString).jpg")
        deleteSnapshot(at: snapshotURL)

        do {
            try writeMetadataJSON(remainingMetadata, to: metaURL)
            WidgetCenter.shared.reloadTimelines(ofKind: SharedWidgetConstants.widgetKind)
        } catch {
            print("[WidgetSync] Failed to remove board: \(error)")
        }
    }

    // MARK: - ディープリンク

    /// ボードへのディープリンクURLを生成する
    static func deepLinkURL(for boardId: UUID) -> URL {
        URL(string: "\(SharedWidgetConstants.deepLinkScheme)://\(SharedWidgetConstants.deepLinkBoardHost)/\(boardId.uuidString)")!
    }

    /// ディープリンクURLからボードIDをパースする
    static func parseBoardId(from url: URL) -> UUID? {
        guard url.scheme == SharedWidgetConstants.deepLinkScheme,
              url.host == SharedWidgetConstants.deepLinkBoardHost else { return nil }
        let path = url.pathComponents
        guard path.count >= 2 else { return nil }
        return UUID(uuidString: path.last ?? "")
    }
}

enum WidgetSyncError: LocalizedError {
    case snapshotEncodingFailed

    var errorDescription: String? {
        switch self {
        case .snapshotEncodingFailed: return "スナップショット画像のエンコードに失敗しました"
        }
    }
}
