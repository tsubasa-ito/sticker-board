import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

struct BackgroundRemover {

    private static let ciContext = SharedCIContext.shared

    private static let maxImageDimension: CGFloat = 2048

    /// EXIF の向き情報を適用し、メモリ節約のためリサイズも行う
    private static func normalizeOrientation(_ image: UIImage) -> UIImage {
        let size = image.size
        let needsResize = max(size.width, size.height) > maxImageDimension
        let needsRotation = image.imageOrientation != .up

        guard needsResize || needsRotation else { return image }

        let targetSize: CGSize
        if needsResize {
            let scale = maxImageDimension / max(size.width, size.height)
            targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        } else {
            targetSize = size
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

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
        let normalized = normalizeOrientation(image)
        #if targetEnvironment(simulator)
        return normalized
        #else
        return try removeBackgroundReal(from: normalized)
        #endif
    }

    /// 背景除去の結果とマスク画像を一緒に返す（マスク編集用）
    static func removeBackgroundWithMask(from image: UIImage) async throws -> BackgroundRemovalResult {
        let normalized = normalizeOrientation(image)
        #if targetEnvironment(simulator)
        let renderer = UIGraphicsImageRenderer(size: normalized.size)
        let whiteMask = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: normalized.size))
        }
        return BackgroundRemovalResult(processedImage: normalized, maskImage: whiteMask, originalImage: normalized)
        #else
        return try removeBackgroundWithMaskReal(from: normalized)
        #endif
    }

    /// 画像内の複数オブジェクトを個別に切り抜いて返す
    static func extractIndividualStickers(from image: UIImage) async throws -> [UIImage] {
        let normalized = normalizeOrientation(image)
        #if targetEnvironment(simulator)
        return [normalized]
        #else
        return try extractIndividualStickersReal(from: normalized)
        #endif
    }

    private static func removeBackgroundWithMaskReal(from image: UIImage) throws -> BackgroundRemovalResult {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemoverError.invalidImage
        }

        let (observation, handler) = try performInstanceMask(on: cgImage)

        // マスクを UIImage として取得
        let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)
        let ciMask = CIImage(cvPixelBuffer: maskPixelBuffer)
        guard let maskCGImage = ciContext.createCGImage(ciMask, from: ciMask.extent) else {
            throw BackgroundRemoverError.renderFailed
        }
        let maskImage = UIImage(cgImage: maskCGImage)

        // 合成画像を生成
        let processedImage = try applyMask(observation, instances: observation.allInstances, to: cgImage, handler: handler)

        return BackgroundRemovalResult(processedImage: processedImage, maskImage: maskImage, originalImage: image)
    }

    private static func removeBackgroundReal(from image: UIImage) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemoverError.invalidImage
        }

        let (observation, handler) = try performInstanceMask(on: cgImage)
        return try applyMask(observation, instances: observation.allInstances, to: cgImage, handler: handler)
    }

    private static func extractIndividualStickersReal(from image: UIImage) throws -> [UIImage] {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemoverError.invalidImage
        }

        let (observation, handler) = try performInstanceMask(on: cgImage)
        let allInstances = observation.allInstances

        if allInstances.count <= 1 {
            let single = try applyMask(observation, instances: allInstances, to: cgImage, handler: handler)
            return [single]
        }

        var results: [UIImage] = []
        for instanceId in allInstances {
            let image: UIImage? = try autoreleasepool {
                let singleSet = IndexSet(integer: instanceId)
                let maskedBuffer = try observation.generateMaskedImage(
                    ofInstances: singleSet,
                    from: handler,
                    croppedToInstancesExtent: true
                )
                let ciImage = CIImage(cvPixelBuffer: maskedBuffer)
                guard let outputCGImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
                    return nil
                }
                return UIImage(cgImage: outputCGImage)
            }
            if let image { results.append(image) }
        }

        if results.isEmpty {
            throw BackgroundRemoverError.noResult
        }
        return results
    }

    private static func performInstanceMask(on cgImage: CGImage) throws -> (VNInstanceMaskObservation, VNImageRequestHandler) {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let result = request.results?.first else {
            throw BackgroundRemoverError.noResult
        }
        return (result, handler)
    }

    private static func applyMask(_ observation: VNInstanceMaskObservation, instances: IndexSet, to cgImage: CGImage, handler: VNImageRequestHandler) throws -> UIImage {
        let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: instances, from: handler)

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

        guard let outputCGImage = ciContext.createCGImage(outputImage, from: ciImage.extent) else {
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
