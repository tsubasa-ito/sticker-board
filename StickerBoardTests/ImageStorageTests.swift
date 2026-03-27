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

        #expect(fileName.hasSuffix(".png"))

        // クリーンアップ
        ImageStorage.delete(fileName: fileName)
    }

    @Test func 保存した画像をloadFromDiskで読み込める() throws {
        let image = makeTestImage()
        let fileName = try ImageStorage.save(image)

        let loaded = ImageStorage.loadFromDisk(fileName: fileName)
        #expect(loaded != nil)

        // クリーンアップ
        ImageStorage.delete(fileName: fileName)
    }

    @Test func 削除後はloadFromDiskでnilが返る() throws {
        let image = makeTestImage()
        let fileName = try ImageStorage.save(image)

        ImageStorage.delete(fileName: fileName)

        let loaded = ImageStorage.loadFromDisk(fileName: fileName)
        #expect(loaded == nil)
    }

    @Test func 存在しないファイル名はnilを返す() {
        let result = ImageStorage.loadFromDisk(fileName: "nonexistent_file.png")
        #expect(result == nil)
    }

    // MARK: - リサイズ

    @Test func 大きい画像も保存と読み込みが正常に動作する() throws {
        let image = makeTestImage(size: CGSize(width: 3000, height: 2000))
        let fileName = try ImageStorage.save(image)

        let loaded = ImageStorage.loadFromDisk(fileName: fileName)
        #expect(loaded != nil)
        #expect(loaded!.size.width > 0)
        #expect(loaded!.size.height > 0)

        ImageStorage.delete(fileName: fileName)
    }
}
