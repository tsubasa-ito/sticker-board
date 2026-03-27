import Testing
import UIKit
@testable import StickerBoard

struct BackgroundImageStorageTests {

    private func makeTestImage(size: CGSize = CGSize(width: 500, height: 400)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - 保存・読み込み・削除

    @Test func 保存したファイル名がJPG拡張子を持つ() throws {
        let image = makeTestImage()
        let fileName = try BackgroundImageStorage.save(image)

        #expect(fileName.hasSuffix(".jpg"))

        BackgroundImageStorage.delete(fileName: fileName)
    }

    @Test func 保存した画像をloadで読み込める() throws {
        let image = makeTestImage()
        let fileName = try BackgroundImageStorage.save(image)

        let loaded = BackgroundImageStorage.load(fileName: fileName)
        #expect(loaded != nil)

        BackgroundImageStorage.delete(fileName: fileName)
    }

    @Test func 削除後はloadでnilが返る() throws {
        let image = makeTestImage()
        let fileName = try BackgroundImageStorage.save(image)

        BackgroundImageStorage.delete(fileName: fileName)

        let loaded = BackgroundImageStorage.load(fileName: fileName)
        #expect(loaded == nil)
    }

    @Test func 存在しないファイル名はnilを返す() {
        let result = BackgroundImageStorage.load(fileName: "nonexistent_bg.jpg")
        #expect(result == nil)
    }

    // MARK: - リサイズ

    @Test func 大きい画像も保存と読み込みが正常に動作する() throws {
        let image = makeTestImage(size: CGSize(width: 5000, height: 3000))
        let fileName = try BackgroundImageStorage.save(image)

        let loaded = try #require(BackgroundImageStorage.load(fileName: fileName))
        #expect(loaded.size.width > 0)
        #expect(loaded.size.height > 0)

        BackgroundImageStorage.delete(fileName: fileName)
    }
}
