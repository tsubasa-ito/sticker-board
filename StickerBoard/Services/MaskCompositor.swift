import UIKit
import CoreImage

struct BackgroundRemovalResult {
    let processedImage: UIImage
    let maskImage: UIImage
    let originalImage: UIImage
}

struct MaskCompositor {

    private static let ciContext = SharedCIContext.shared

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

    /// 透過画像のアルファチャネルからグレースケールマスクを生成する
    /// 不透明ピクセル → 白(255)、透明ピクセル → 黒(0)
    static func generateMaskFromAlpha(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        // RGBA で元画像を描画してピクセルデータを取得
        guard let rgbaContext = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        rgbaContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let rgbaData = rgbaContext.data else { return nil }
        let rgbaBuffer = rgbaData.bindMemory(to: UInt8.self, capacity: width * height * 4)

        // グレースケール（マスク用）コンテキストを作成
        guard let maskContext = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        guard let maskData = maskContext.data else { return nil }
        let maskBuffer = maskData.bindMemory(to: UInt8.self, capacity: width * height)

        // アルファチャネル(各ピクセルの4バイト目)をマスク値に変換
        for i in 0..<(width * height) {
            let alpha = rgbaBuffer[i * 4 + 3]
            maskBuffer[i] = alpha > 0 ? 255 : 0
        }

        guard let maskCGImage = maskContext.makeImage() else { return nil }
        return UIImage(cgImage: maskCGImage)
    }
}
