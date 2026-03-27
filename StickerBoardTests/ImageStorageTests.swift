import Testing
import UIKit
@testable import StickerBoard

struct ImageStorageTests {

    /// テスト用画像を生成（scale=1.0でピクセル=ポイント）
    private func makeTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - 保存・読み込み・削除

    @Test func 保存したファイル名がPNG拡張子を持つ() throws {
        let image = makeTestImage()
        let fileName = try ImageStorage.save(image)
        defer { try? ImageStorage.delete(fileName: fileName) }

        #expect(fileName.hasSuffix(".png"))
    }

    @Test func 保存した画像をloadFromDiskで読み込める() throws {
        let image = makeTestImage()
        let fileName = try ImageStorage.save(image)
        defer { try? ImageStorage.delete(fileName: fileName) }

        let loaded = ImageStorage.loadFromDisk(fileName: fileName)
        #expect(loaded != nil)
    }

    @Test func 削除後はloadFromDiskでnilが返る() throws {
        let image = makeTestImage()
        let fileName = try ImageStorage.save(image)

        try ImageStorage.delete(fileName: fileName)

        let loaded = ImageStorage.loadFromDisk(fileName: fileName)
        #expect(loaded == nil)
    }

    @Test func 存在しないファイル名はnilを返す() {
        let result = ImageStorage.loadFromDisk(fileName: "nonexistent_file.png")
        #expect(result == nil)
    }

    // MARK: - 上書き保存

    @Test func 上書き保存で同じファイル名に画像が更新される() throws {
        let original = makeTestImage(size: CGSize(width: 100, height: 100))
        let fileName = try ImageStorage.save(original)
        defer { try? ImageStorage.delete(fileName: fileName) }

        let beforeOverwrite = try #require(ImageStorage.loadFromDisk(fileName: fileName))
        let beforeData = try #require(beforeOverwrite.pngData())

        let replacement = makeTestImage(size: CGSize(width: 80, height: 80))
        try ImageStorage.overwrite(replacement, fileName: fileName)

        let loaded = try #require(ImageStorage.loadFromDisk(fileName: fileName))
        let afterData = try #require(loaded.pngData())

        // 上書き前後でファイル内容が変わっていることを検証
        #expect(beforeData != afterData)
    }

    @Test func 上書き保存後もloadFromDiskで読み込める() throws {
        let image = makeTestImage()
        let fileName = try ImageStorage.save(image)
        defer { try? ImageStorage.delete(fileName: fileName) }

        let updated = makeTestImage(size: CGSize(width: 50, height: 50))
        try ImageStorage.overwrite(updated, fileName: fileName)

        let loaded = ImageStorage.loadFromDisk(fileName: fileName)
        #expect(loaded != nil)
    }

    // MARK: - リサイズ

    @Test func 大きい画像も保存と読み込みが正常に動作する() throws {
        let image = makeTestImage(size: CGSize(width: 3000, height: 2000))
        let fileName = try ImageStorage.save(image)
        defer { try? ImageStorage.delete(fileName: fileName) }

        let loaded = try #require(ImageStorage.loadFromDisk(fileName: fileName))
        #expect(loaded.size.width > 0)
        #expect(loaded.size.height > 0)
    }
}
