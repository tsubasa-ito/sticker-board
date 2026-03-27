import Testing
import UIKit
@testable import StickerBoard

struct UIImageExtensionTests {

    // MARK: - estimatedMemoryCost

    @Test func estimatedMemoryCostが正の値を返す() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        }

        #expect(image.estimatedMemoryCost > 0)
    }

    // MARK: - resized

    @Test func maxDimensionより大きい画像はリサイズされる() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 1000))
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 2000, height: 1000)))
        }

        let resized = image.resized(maxDimension: 500)

        #expect(resized.size.width == 500)
        #expect(resized.size.height == 250)
    }

    @Test func maxDimension以下の画像はそのまま返る() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 150))
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 200, height: 150)))
        }

        let resized = image.resized(maxDimension: 500)

        #expect(resized.size.width == 200)
        #expect(resized.size.height == 150)
    }

    @Test func アスペクト比が維持される() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1600, height: 900))
        let image = renderer.image { ctx in
            UIColor.gray.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 1600, height: 900)))
        }

        let resized = image.resized(maxDimension: 800)

        let ratio = resized.size.width / resized.size.height
        let originalRatio = 1600.0 / 900.0
        #expect(abs(ratio - originalRatio) < 0.01)
    }

    // MARK: - alphaTrimmed

    @Test func 透明余白がトリミングされる() throws {
        // scale=1 で生成してピクセル座標を一致させる
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200), format: format)
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 75, y: 75, width: 50, height: 50))
        }

        let trimmed = image.alphaTrimmed()
        let cgImage = try #require(trimmed.cgImage)

        #expect(cgImage.width == 50)
        #expect(cgImage.height == 50)
    }

    @Test func 不透明画像はトリミングされない() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 80), format: format)
        let image = renderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 100, height: 80)))
        }

        let trimmed = image.alphaTrimmed()
        let cgImage = try #require(trimmed.cgImage)

        #expect(cgImage.width == 100)
        #expect(cgImage.height == 80)
    }
}
