import Testing
import UIKit
@testable import StickerBoard

struct MaskCompositorTests {

    private func makeOpaqueImage(size: CGSize = CGSize(width: 100, height: 100), color: UIColor = .red) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - マスク合成

    @Test func 白マスクで合成すると元画像が保持される() throws {
        let original = makeOpaqueImage(color: .blue)
        let whiteMask = makeOpaqueImage(color: .white)

        let result = try #require(MaskCompositor.compositeWithMask(original: original, mask: whiteMask))

        #expect(result.cgImage?.width == original.cgImage?.width)
        #expect(result.cgImage?.height == original.cgImage?.height)
    }

    @Test func マスクが元画像と異なるサイズでも合成できる() throws {
        let original = makeOpaqueImage(size: CGSize(width: 200, height: 200), color: .green)
        let mask = makeOpaqueImage(size: CGSize(width: 50, height: 50), color: .white)

        let result = try #require(MaskCompositor.compositeWithMask(original: original, mask: mask))

        #expect(result.cgImage?.width == original.cgImage?.width)
        #expect(result.cgImage?.height == original.cgImage?.height)
    }

    // MARK: - アルファチャネルからマスク生成

    private func makeTestImage(size: CGSize, color: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    @Test func 不透明画像から白マスクが生成される() throws {
        let opaque = makeTestImage(size: CGSize(width: 50, height: 50), color: .red)
        let mask = try #require(MaskCompositor.generateMaskFromAlpha(image: opaque))

        let cg = try #require(mask.cgImage)
        #expect(cg.width == 50)
        #expect(cg.height == 50)

        // マスクの中央ピクセルが白(255)であることを確認
        let data = try #require(cg.dataProvider?.data as Data?)
        let centerIndex = 25 * cg.bytesPerRow + 25
        #expect(data[centerIndex] == 255)
    }

    @Test func 透明画像から黒マスクが生成される() throws {
        let transparent = makeTestImage(size: CGSize(width: 50, height: 50), color: .clear)

        let mask = try #require(MaskCompositor.generateMaskFromAlpha(image: transparent))
        let cg = try #require(mask.cgImage)

        let data = try #require(cg.dataProvider?.data as Data?)
        let centerIndex = 25 * cg.bytesPerRow + 25
        #expect(data[centerIndex] == 0)
    }

    @Test func マスクサイズが元画像と一致する() throws {
        let image = makeTestImage(size: CGSize(width: 120, height: 80), color: .blue)
        let mask = try #require(MaskCompositor.generateMaskFromAlpha(image: image))
        let cg = try #require(mask.cgImage)

        #expect(cg.width == 120)
        #expect(cg.height == 80)
    }
}
