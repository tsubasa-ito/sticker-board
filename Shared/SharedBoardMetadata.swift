import Foundation

/// ウィジェットとメインアプリ間で共有するボードメタデータ
struct SharedBoardMetadata: Codable, Sendable {
    let id: String
    let title: String
    let stickerCount: Int
    let updatedAt: Date
    let snapshotFileName: String
}
