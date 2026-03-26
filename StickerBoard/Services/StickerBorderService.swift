import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct StickerBorderService {

    private static let ciContext = CIContext()

    /// シール画像にアルファマスクベースの枠線を追加
    static func applyBorder(to image: UIImage, width: StickerBorderWidth, colorHex: String) -> UIImage? {
        guard width != .none else { return image }

        return autoreleasepool {
            guard let ciImage = CIImage(image: image) else { return image }
            let extent = ciImage.extent
            let shortSide = min(extent.width, extent.height)
            let radius = Float(shortSide * width.radiusRatio)

            guard radius > 0 else { return image }

            // 1. アルファマスクを抽出
            guard let alphaMask = extractAlpha(from: ciImage) else { return image }

            // 2. モルフォロジー（膨張）でアルファマスクを拡大
            let morphology = CIFilter.morphologyMaximum()
            morphology.inputImage = alphaMask
            morphology.radius = radius
            guard let expandedMask = morphology.outputImage?.cropped(to: extent) else { return image }

            // 3. 枠線カラーのソリッド画像を生成
            let borderColor = colorFromHex(colorHex)
            let solidColor = CIImage(color: borderColor).cropped(to: extent)

            // 4. 拡大マスクで枠線カラーをマスク → 枠線シェイプ
            let maskedBorder = CIFilter.blendWithMask()
            maskedBorder.inputImage = solidColor
            maskedBorder.backgroundImage = CIImage.empty()
            maskedBorder.maskImage = expandedMask
            guard let borderShape = maskedBorder.outputImage else { return image }

            // 5. 元画像を枠線の上に合成
            let composite = CIFilter.sourceOverCompositing()
            composite.inputImage = ciImage
            composite.backgroundImage = borderShape
            guard let result = composite.outputImage else { return image }

            // 6. UIImage に変換（元画像と同じサイズに維持）
            guard let cgImage = ciContext.createCGImage(result, from: extent) else { return image }
            return UIImage(cgImage: cgImage)
        }
    }

    // MARK: - ヘルパー

    private static func extractAlpha(from image: CIImage) -> CIImage? {
        let alphaFilter = CIFilter.colorMatrix()
        alphaFilter.inputImage = image
        alphaFilter.rVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaFilter.gVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaFilter.bVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaFilter.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaFilter.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        return alphaFilter.outputImage
    }

    private static func colorFromHex(_ hex: String) -> CIColor {
        let hexValue = UInt(hex, radix: 16) ?? 0xFFFFFF
        let r = CGFloat((hexValue >> 16) & 0xFF) / 255.0
        let g = CGFloat((hexValue >> 8) & 0xFF) / 255.0
        let b = CGFloat(hexValue & 0xFF) / 255.0
        return CIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
