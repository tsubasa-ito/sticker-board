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
}
