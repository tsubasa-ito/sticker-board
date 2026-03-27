import Testing
import UIKit
@testable import StickerBoard

struct StickerFilterServiceTests {

    /// テスト用の不透明な画像を生成
    private func makeTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// テスト用のアルファ付き画像を生成（中央に円を描画）
    private func makeAlphaTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.blue.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 10, y: 10, width: 80, height: 80))
        }
    }

    // MARK: - オリジナルフィルター

    @Test func originalフィルターは元画像をそのまま返す() {
        let image = makeTestImage()
        let result = StickerFilterService.apply(.original, to: image)

        // 同一インスタンスが返ること
        #expect(result === image)
    }

    // MARK: - 全フィルターが画像を返す

    @Test(arguments: StickerFilter.allCases)
    func フィルター適用後にnilでない画像が返る(filter: StickerFilter) {
        let image = makeAlphaTestImage()
        let result = StickerFilterService.apply(filter, to: image)

        #expect(result.size.width > 0)
        #expect(result.size.height > 0)
    }

    @Test(arguments: StickerFilter.allCases.filter { $0 != .original })
    func フィルター適用後のサイズが元画像と同じ(filter: StickerFilter) {
        let image = makeAlphaTestImage(size: CGSize(width: 200, height: 150))
        let result = StickerFilterService.apply(filter, to: image)

        // CGImage ベースのサイズ比較（ピクセル単位）
        #expect(result.cgImage?.width == image.cgImage?.width)
        #expect(result.cgImage?.height == image.cgImage?.height)
    }
}
