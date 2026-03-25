import UIKit
import CoreImage

struct BackgroundRemovalResult {
    let processedImage: UIImage
    let maskImage: UIImage
    let originalImage: UIImage
}

struct MaskCompositor {

    private static let ciContext = CIContext()

    /// マスク画像を使って元画像の背景を透明にする
    static func compositeWithMask(original: UIImage, mask: UIImage) -> UIImage? {
        guard let originalCG = original.cgImage,
              let maskCG = mask.cgImage else {
            return nil
        }

        let ciOriginal = CIImage(cgImage: originalCG)
        let ciMask = CIImage(cgImage: maskCG)

        // マスクを元画像サイズにスケーリング
        let scaleX = ciOriginal.extent.width / ciMask.extent.width
        let scaleY = ciOriginal.extent.height / ciMask.extent.height
        let scaledMask = ciMask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let filter = CIFilter(name: "CIBlendWithMask") else {
            return nil
        }
        filter.setValue(ciOriginal, forKey: kCIInputImageKey)
        filter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
        filter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)

        guard let outputImage = filter.outputImage,
              let outputCG = ciContext.createCGImage(outputImage, from: ciOriginal.extent) else {
            return nil
        }

        return UIImage(cgImage: outputCG)
    }
}
