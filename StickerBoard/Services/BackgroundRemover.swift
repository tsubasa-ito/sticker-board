import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

struct BackgroundRemover {

    /// シミュレータかどうかを判定
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// 画像から前景（シール）を切り抜いて背景を透明にする
    static func removeBackground(from image: UIImage) async throws -> UIImage {
        // シミュレータでは Vision の背景除去が動作しないため、
        // 元画像をそのまま返す（実機でのみ背景除去が有効）
        #if targetEnvironment(simulator)
        return image
        #else
        return try removeBackgroundReal(from: image)
        #endif
    }

    private static func removeBackgroundReal(from image: UIImage) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemoverError.invalidImage
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let result = request.results?.first else {
            throw BackgroundRemoverError.noResult
        }

        return try applyMask(result, to: cgImage, handler: handler)
    }

    private static func applyMask(_ observation: VNInstanceMaskObservation, to cgImage: CGImage, handler: VNImageRequestHandler) throws -> UIImage {
        let allInstances = observation.allInstances
        let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: allInstances, from: handler)

        let ciMask = CIImage(cvPixelBuffer: maskPixelBuffer)
        let ciImage = CIImage(cgImage: cgImage)

        let scaleX = ciImage.extent.width / ciMask.extent.width
        let scaleY = ciImage.extent.height / ciMask.extent.height
        let scaledMask = ciMask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let filter = CIFilter(name: "CIBlendWithMask") else {
            throw BackgroundRemoverError.filterFailed
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
        filter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)

        guard let outputImage = filter.outputImage else {
            throw BackgroundRemoverError.filterFailed
        }

        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            throw BackgroundRemoverError.renderFailed
        }

        return UIImage(cgImage: outputCGImage)
    }
}

enum BackgroundRemoverError: LocalizedError {
    case invalidImage
    case noResult
    case filterFailed
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "画像を読み込めませんでした"
        case .noResult: return "背景除去の結果を取得できませんでした"
        case .filterFailed: return "画像フィルタの適用に失敗しました"
        case .renderFailed: return "画像の生成に失敗しました"
        }
    }
}
