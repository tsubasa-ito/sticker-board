import Foundation

/// ウィジェットとメインアプリ間で共有するボードメタデータ
struct SharedBoardMetadata: Codable, Sendable {
    let id: String
    let title: String
    let stickerCount: Int
    let updatedAt: Date
    let snapshotFileName: String
    /// largeウィジェット専用スナップショットのファイル名（nil = 未生成）
    var largeSnapshotFileName: String?

    init(
        id: String,
        title: String,
        stickerCount: Int,
        updatedAt: Date,
        snapshotFileName: String,
        largeSnapshotFileName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.stickerCount = stickerCount
        self.updatedAt = updatedAt
        self.snapshotFileName = snapshotFileName
        self.largeSnapshotFileName = largeSnapshotFileName
    }
}
