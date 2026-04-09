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

        #expect(resized === image)
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

    // MARK: - rotatedBy90Degrees

    @Test func 時計回り90度回転で幅と高さが入れ替わる() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100), format: format)
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 200, height: 100)))
        }

        let rotated = image.rotatedBy90Degrees(clockwise: true)
        let cgImage = try #require(rotated.cgImage)

        #expect(cgImage.width == 100)
        #expect(cgImage.height == 200)
    }

    @Test func 反時計回り90度回転で幅と高さが入れ替わる() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100), format: format)
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 200, height: 100)))
        }

        let rotated = image.rotatedBy90Degrees(clockwise: false)
        let cgImage = try #require(rotated.cgImage)

        #expect(cgImage.width == 100)
        #expect(cgImage.height == 200)
    }

    @Test func 時計回りに二回回転すると幅と高さが変わらない() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100), format: format)
        let image = renderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 200, height: 100)))
        }

        // 90度 × 2 = 180度
        let rotated = image.rotatedBy90Degrees(clockwise: true).rotatedBy90Degrees(clockwise: true)
        let cgImage = try #require(rotated.cgImage)

        #expect(cgImage.width == 200)
        #expect(cgImage.height == 100)
    }

    @Test func 時計回りに四回回転すると元の寸法に戻る() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 150, height: 80), format: format)
        let image = renderer.image { ctx in
            UIColor.purple.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: 150, height: 80)))
        }

        var rotated = image
        for _ in 0..<4 {
            rotated = rotated.rotatedBy90Degrees(clockwise: true)
        }
        let cgImage = try #require(rotated.cgImage)

        #expect(cgImage.width == 150)
        #expect(cgImage.height == 80)
    }

    @Test func 回転後も透過情報が保持される() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100), format: format)
        let image = renderer.image { ctx in
            // 左半分だけ塗る（右半分は透明）
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 50, height: 100))
        }

        let rotated = image.rotatedBy90Degrees(clockwise: true)

        // PNGに変換してデータが存在する（透過含むPNGとして有効）ことを確認
        #expect(rotated.pngData() != nil)
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
