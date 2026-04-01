import Testing
import Foundation
import UIKit
@testable import StickerBoard

struct WidgetDataSyncServiceTests {

    // MARK: - メタデータ生成

    @Test func generateMetadataで正しいBoardMetadataが生成される() {
        let boardId = UUID()
        let updatedAt = Date()
        let metadata = WidgetDataSyncService.generateMetadata(
            boardId: boardId,
            title: "テストボード",
            stickerCount: 5,
            updatedAt: updatedAt
        )

        #expect(metadata.id == boardId.uuidString)
        #expect(metadata.title == "テストボード")
        #expect(metadata.stickerCount == 5)
        #expect(metadata.updatedAt == updatedAt)
        #expect(metadata.snapshotFileName == "\(boardId.uuidString).jpg")
    }

    @Test func generateMetadataでシール0枚の場合も正しく生成される() {
        let boardId = UUID()
        let metadata = WidgetDataSyncService.generateMetadata(
            boardId: boardId,
            title: "空ボード",
            stickerCount: 0,
            updatedAt: Date()
        )

        #expect(metadata.stickerCount == 0)
        #expect(metadata.title == "空ボード")
    }

    // MARK: - メタデータJSON書き出し・読み込み

    @Test func メタデータJSONの書き出しと読み込みが往復できる() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let metadata = [
            BoardMetadata(
                id: UUID().uuidString,
                title: "ボード1",
                stickerCount: 3,
                updatedAt: Date(),
                snapshotFileName: "board1.jpg"
            ),
            BoardMetadata(
                id: UUID().uuidString,
                title: "ボード2",
                stickerCount: 7,
                updatedAt: Date(),
                snapshotFileName: "board2.jpg"
            )
        ]

        let jsonURL = tempDir.appendingPathComponent("boards_meta.json")
        try WidgetDataSyncService.writeMetadataJSON(metadata, to: jsonURL)

        let loaded = try WidgetDataSyncService.readMetadataJSON(from: jsonURL)
        #expect(loaded.count == 2)
        #expect(loaded[0].title == "ボード1")
        #expect(loaded[1].title == "ボード2")
        #expect(loaded[0].stickerCount == 3)
        #expect(loaded[1].stickerCount == 7)
    }

    @Test func 空配列のメタデータJSONの書き出しと読み込み() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let jsonURL = tempDir.appendingPathComponent("boards_meta.json")
        try WidgetDataSyncService.writeMetadataJSON([], to: jsonURL)

        let loaded = try WidgetDataSyncService.readMetadataJSON(from: jsonURL)
        #expect(loaded.isEmpty)
    }

    // MARK: - スナップショット画像の保存・削除

    @Test func スナップショット画像の保存と存在確認() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let boardId = UUID()
        let fileName = "\(boardId.uuidString).jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)

        // 1x1 の赤い画像を作成
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let testImage = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }

        try WidgetDataSyncService.saveSnapshot(testImage, to: fileURL)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        // 読み込みテスト
        let data = try Data(contentsOf: fileURL)
        #expect(!data.isEmpty)
    }

    @Test func スナップショット画像の削除() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("test.jpg")

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let testImage = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }

        try WidgetDataSyncService.saveSnapshot(testImage, to: fileURL)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        WidgetDataSyncService.deleteSnapshot(at: fileURL)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    // MARK: - ディープリンクURL生成

    @Test func ディープリンクURLが正しく生成される() {
        let boardId = UUID()
        let url = WidgetDataSyncService.deepLinkURL(for: boardId)

        #expect(url.scheme == "stickerboard")
        #expect(url.host == "board")
        #expect(url.pathComponents.last == boardId.uuidString)
    }

    // MARK: - ディープリンクURLパース

    @Test func ディープリンクURLからボードIDをパースできる() {
        let boardId = UUID()
        let url = URL(string: "stickerboard://board/\(boardId.uuidString)")!

        let parsedId = WidgetDataSyncService.parseBoardId(from: url)
        #expect(parsedId == boardId)
    }

    @Test func 不正なディープリンクURLからはnilが返る() {
        let url = URL(string: "stickerboard://settings")!
        let parsedId = WidgetDataSyncService.parseBoardId(from: url)
        #expect(parsedId == nil)
    }

    @Test func 不正なUUID文字列からはnilが返る() {
        let url = URL(string: "stickerboard://board/invalid-uuid")!
        let parsedId = WidgetDataSyncService.parseBoardId(from: url)
        #expect(parsedId == nil)
    }
}
