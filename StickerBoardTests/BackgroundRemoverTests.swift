import Testing
import UIKit
@testable import StickerBoard

struct BackgroundRemoverTests {

    private func makeTestImage(size: CGSize = CGSize(width: 100, height: 100), color: UIColor = .red) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - removeBackgroundAtPoint（シミュレータ）

    @Test func removeBackgroundAtPoint_シミュレータで元画像サイズの結果を返す() async throws {
        let image = makeTestImage()
        let result = try await BackgroundRemover.removeBackgroundAtPoint(
            from: image,
            normalizedPoint: CGPoint(x: 0.5, y: 0.5)
        )

        #expect(result.processedImage.size.width == image.size.width)
        #expect(result.processedImage.size.height == image.size.height)
        #expect(result.originalImage.size == image.size)
    }

    @Test func removeBackgroundAtPoint_マスク画像が生成される() async throws {
        let image = makeTestImage()
        let result = try await BackgroundRemover.removeBackgroundAtPoint(
            from: image,
            normalizedPoint: CGPoint(x: 0.5, y: 0.5)
        )

        #expect(result.maskImage.size.width > 0)
        #expect(result.maskImage.size.height > 0)
    }

    @Test func removeBackgroundAtPoint_座標0_0でクラッシュしない() async throws {
        let image = makeTestImage()
        let result = try await BackgroundRemover.removeBackgroundAtPoint(
            from: image,
            normalizedPoint: CGPoint(x: 0, y: 0)
        )
        #expect(result.processedImage.size.width > 0)
    }

    @Test func removeBackgroundAtPoint_座標1_1でクラッシュしない() async throws {
        let image = makeTestImage()
        let result = try await BackgroundRemover.removeBackgroundAtPoint(
            from: image,
            normalizedPoint: CGPoint(x: 1, y: 1)
        )
        #expect(result.processedImage.size.width > 0)
    }

    @Test func removeBackgroundAtPoint_大きい画像がリサイズされる() async throws {
        let largeImage = makeTestImage(size: CGSize(width: 4000, height: 3000))
        let result = try await BackgroundRemover.removeBackgroundAtPoint(
            from: largeImage,
            normalizedPoint: CGPoint(x: 0.5, y: 0.5)
        )

        // 長辺2048pxにリサイズされる
        let maxDimension = max(result.processedImage.size.width, result.processedImage.size.height)
        #expect(maxDimension <= 2048)
    }

    // MARK: - BackgroundRemoverError

    @Test func noSubjectAtPointエラーの説明文に被写体が含まれる() {
        let error = BackgroundRemoverError.noSubjectAtPoint
        let description = error.errorDescription ?? ""
        #expect(description.contains("被写体"))
    }

    @Test func noSubjectAtPointエラーの等価比較() {
        let error: BackgroundRemoverError = .noSubjectAtPoint
        #expect(error == .noSubjectAtPoint)
        #expect(error != .invalidImage)
    }

    // MARK: - removeBackgroundWithMask（シミュレータ）

    @Test func removeBackgroundWithMask_シミュレータで正常に返す() async throws {
        let image = makeTestImage()
        let result = try await BackgroundRemover.removeBackgroundWithMask(from: image)

        #expect(result.processedImage.size == image.size)
        #expect(result.maskImage.size.width > 0)
        #expect(result.originalImage.size == image.size)
    }

    // MARK: - isSimulator

    @Test func isSimulator_シミュレータ環境でtrueを返す() {
        #if targetEnvironment(simulator)
        #expect(BackgroundRemover.isSimulator == true)
        #else
        #expect(BackgroundRemover.isSimulator == false)
        #endif
    }
}
