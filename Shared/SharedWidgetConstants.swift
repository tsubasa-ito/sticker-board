import Foundation

/// ウィジェットとメインアプリ間で共有する定数
enum SharedWidgetConstants {
    static let appGroupID = "group.com.tebasaki.StickerBoard"
    static let widgetDataDirectory = "WidgetData"
    static let snapshotsDirectory = "board_snapshots"
    static let metadataFileName = "boards_meta.json"
    static let widgetKind = "BoardShowcaseWidget"
    static let deepLinkScheme = "stickerboard"
    static let deepLinkBoardHost = "board"
}
