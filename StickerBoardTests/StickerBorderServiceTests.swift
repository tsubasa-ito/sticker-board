import Testing
import UIKit
@testable import StickerBoard

struct StickerBorderServiceTests {

    /// テスト用のアルファ付き画像（中央に丸）
    private func makeAlphaTestImage(size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.red.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 20, y: 20, width: 160, height: 160))
        }
    }

    // MARK: - none は元画像を返す

    @Test func noneの場合は元画像をそのまま返す() {
        let image = makeAlphaTestImage()
        let result = StickerBorderService.applyBorder(to: image, width: .none, colorHex: "FFFFFF")

        #expect(result === image)
    }

    // MARK: - 枠線適用

    @Test(arguments: [StickerBorderWidth.thin, .medium, .thick])
    func 枠線適用後にnilでない画像が返る(width: StickerBorderWidth) throws {
        let image = makeAlphaTestImage()
        let result = try #require(StickerBorderService.applyBorder(to: image, width: width, colorHex: "FF0000"))

        #expect(result.size.width > 0)
        #expect(result.size.height > 0)
    }

    @Test func 枠線適用後のピクセルサイズが元画像と同じ() throws {
        let image = makeAlphaTestImage(size: CGSize(width: 300, height: 250))
        let result = try #require(StickerBorderService.applyBorder(to: image, width: .medium, colorHex: "000000"))

        #expect(result.cgImage?.width == image.cgImage?.width)
        #expect(result.cgImage?.height == image.cgImage?.height)
    }

    // MARK: - 異なるカラーhex

    @Test(arguments: ["FFFFFF", "000000", "FF0000", "00FF00", "0000FF"])
    func 各カラーhexで枠線適用がクラッシュしない(hex: String) throws {
        let image = makeAlphaTestImage()
        let result = try #require(StickerBorderService.applyBorder(to: image, width: .medium, colorHex: hex))

        #expect(result.size.width > 0)
    }
}
