import Testing
import Foundation
@testable import StickerBoard

struct ImageSyncServiceTests {

    private let fileManager = FileManager.default

    /// テスト用のディレクトリ構造を作成し、テスト後にクリーンアップする
    private func withTempDirs(_ body: (URL, URL, URL) async throws -> Void) async throws {
        let base = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let localStickers = base.appendingPathComponent("local/Stickers")
        let localBackgrounds = base.appendingPathComponent("local/Backgrounds")
        let cloudContainer = base.appendingPathComponent("cloud")

        try fileManager.createDirectory(at: localStickers, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: localBackgrounds, withIntermediateDirectories: true)

        defer { try? fileManager.removeItem(at: base) }
        try await body(localStickers, localBackgrounds, cloudContainer)
    }

    private func createTestFile(at directory: URL, name: String, content: String = "test") throws {
        let data = content.data(using: .utf8)!
        try data.write(to: directory.appendingPathComponent(name))
    }

    // MARK: - アップロード（ローカル → クラウド）

    @Test func ローカルのシール画像がクラウドにアップロードされる() async throws {
        try await withTempDirs { localStickers, localBackgrounds, cloud in
            try createTestFile(at: localStickers, name: "sticker1.png")
            try createTestFile(at: localStickers, name: "sticker2.png")

            let service = ImageSyncService()
            let result = try await service.syncImages(
                localStickersURL: localStickers,
                localBackgroundsURL: localBackgrounds,
                cloudContainerURL: cloud
            )

            #expect(result.uploadedCount == 2)
            let cloudStickers = cloud.appendingPathComponent("Documents/Stickers")
            #expect(fileManager.fileExists(atPath: cloudStickers.appendingPathComponent("sticker1.png").path))
            #expect(fileManager.fileExists(atPath: cloudStickers.appendingPathComponent("sticker2.png").path))
        }
    }

    @Test func ローカルの背景画像がクラウドにアップロードされる() async throws {
        try await withTempDirs { localStickers, localBackgrounds, cloud in
            try createTestFile(at: localBackgrounds, name: "bg1.jpg")

            let service = ImageSyncService()
            let result = try await service.syncImages(
                localStickersURL: localStickers,
                localBackgroundsURL: localBackgrounds,
                cloudContainerURL: cloud
            )

            #expect(result.uploadedCount == 1)
            let cloudBackgrounds = cloud.appendingPathComponent("Documents/Backgrounds")
            #expect(fileManager.fileExists(atPath: cloudBackgrounds.appendingPathComponent("bg1.jpg").path))
        }
    }

    // MARK: - ダウンロード（クラウド → ローカル）

    @Test func クラウドのシール画像がローカルにダウンロードされる() async throws {
        try await withTempDirs { localStickers, localBackgrounds, cloud in
            let cloudStickers = cloud.appendingPathComponent("Documents/Stickers")
            try fileManager.createDirectory(at: cloudStickers, withIntermediateDirectories: true)
            try createTestFile(at: cloudStickers, name: "cloud_sticker.png")

            let service = ImageSyncService()
            let result = try await service.syncImages(
                localStickersURL: localStickers,
                localBackgroundsURL: localBackgrounds,
                cloudContainerURL: cloud
            )

            #expect(result.downloadedCount == 1)
            #expect(fileManager.fileExists(atPath: localStickers.appendingPathComponent("cloud_sticker.png").path))
        }
    }

    @Test func クラウドの背景画像がローカルにダウンロードされる() async throws {
        try await withTempDirs { localStickers, localBackgrounds, cloud in
            let cloudBackgrounds = cloud.appendingPathComponent("Documents/Backgrounds")
            try fileManager.createDirectory(at: cloudBackgrounds, withIntermediateDirectories: true)
            try createTestFile(at: cloudBackgrounds, name: "cloud_bg.jpg")

            let service = ImageSyncService()
            let result = try await service.syncImages(
                localStickersURL: localStickers,
                localBackgroundsURL: localBackgrounds,
                cloudContainerURL: cloud
            )

            #expect(result.downloadedCount == 1)
            #expect(fileManager.fileExists(atPath: localBackgrounds.appendingPathComponent("cloud_bg.jpg").path))
        }
    }

    // MARK: - 双方向同期

    @Test func ローカルとクラウド両方に異なるファイルがある場合は双方向同期される() async throws {
        try await withTempDirs { localStickers, localBackgrounds, cloud in
            // ローカルにのみ存在
            try createTestFile(at: localStickers, name: "local_only.png")

            // クラウドにのみ存在
            let cloudStickers = cloud.appendingPathComponent("Documents/Stickers")
            try fileManager.createDirectory(at: cloudStickers, withIntermediateDirectories: true)
            try createTestFile(at: cloudStickers, name: "cloud_only.png")

            let service = ImageSyncService()
            let result = try await service.syncImages(
                localStickersURL: localStickers,
                localBackgroundsURL: localBackgrounds,
                cloudContainerURL: cloud
            )

            #expect(result.uploadedCount == 1)
            #expect(result.downloadedCount == 1)
            // 両方に両ファイルが存在する
            #expect(fileManager.fileExists(atPath: localStickers.appendingPathComponent("cloud_only.png").path))
            #expect(fileManager.fileExists(atPath: cloudStickers.appendingPathComponent("local_only.png").path))
        }
    }

    // MARK: - 重複スキップ

    @Test func 両方に同じファイルがある場合はスキップされる() async throws {
        try await withTempDirs { localStickers, localBackgrounds, cloud in
            try createTestFile(at: localStickers, name: "same.png", content: "same data")

            let cloudStickers = cloud.appendingPathComponent("Documents/Stickers")
            try fileManager.createDirectory(at: cloudStickers, withIntermediateDirectories: true)
            try createTestFile(at: cloudStickers, name: "same.png", content: "same data")

            let service = ImageSyncService()
            let result = try await service.syncImages(
                localStickersURL: localStickers,
                localBackgroundsURL: localBackgrounds,
                cloudContainerURL: cloud
            )

            #expect(result.uploadedCount == 0)
            #expect(result.downloadedCount == 0)
        }
    }

    // MARK: - 空ディレクトリ

    @Test func 空のディレクトリでも正常に動作する() async throws {
        try await withTempDirs { localStickers, localBackgrounds, cloud in
            let service = ImageSyncService()
            let result = try await service.syncImages(
                localStickersURL: localStickers,
                localBackgroundsURL: localBackgrounds,
                cloudContainerURL: cloud
            )

            #expect(result.uploadedCount == 0)
            #expect(result.downloadedCount == 0)
        }
    }

    // MARK: - クラウドディレクトリ自動作成

    @Test func クラウドディレクトリが存在しない場合は自動作成される() async throws {
        try await withTempDirs { localStickers, localBackgrounds, cloud in
            try createTestFile(at: localStickers, name: "test.png")

            let service = ImageSyncService()
            _ = try await service.syncImages(
                localStickersURL: localStickers,
                localBackgroundsURL: localBackgrounds,
                cloudContainerURL: cloud
            )

            let cloudStickers = cloud.appendingPathComponent("Documents/Stickers")
            let cloudBackgrounds = cloud.appendingPathComponent("Documents/Backgrounds")
            var isDir: ObjCBool = false
            #expect(fileManager.fileExists(atPath: cloudStickers.path, isDirectory: &isDir) && isDir.boolValue)
            #expect(fileManager.fileExists(atPath: cloudBackgrounds.path, isDirectory: &isDir) && isDir.boolValue)
        }
    }

    // MARK: - 合算カウント

    @Test func シールと背景のアップロードが合算される() async throws {
        try await withTempDirs { localStickers, localBackgrounds, cloud in
            try createTestFile(at: localStickers, name: "s1.png")
            try createTestFile(at: localStickers, name: "s2.png")
            try createTestFile(at: localBackgrounds, name: "b1.jpg")

            let service = ImageSyncService()
            let result = try await service.syncImages(
                localStickersURL: localStickers,
                localBackgroundsURL: localBackgrounds,
                cloudContainerURL: cloud
            )

            #expect(result.uploadedCount == 3)
        }
    }
}
