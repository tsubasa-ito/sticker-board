import Foundation

/// ウィジェットとメインアプリ間で共有するボードメタデータ
struct BoardMetadata: Codable, Sendable {
    let id: String
    let title: String
    let stickerCount: Int
    let updatedAt: Date
    let snapshotFileName: String
}
