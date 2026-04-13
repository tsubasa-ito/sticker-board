import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// キャプチャフローの処理結果（単一 or 複数シール）
enum CaptureProcessingResult {
    case singleSticker(BackgroundRemovalResult)
    case multipleStickers([UIImage])
}

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
        let whiteMask = createWhiteMask(size: normalized.size)
        return BackgroundRemovalResult(processedImage: normalized, maskImage: whiteMask, originalImage: normalized)
        #else
        return try removeBackgroundWithMaskReal(from: normalized)
        #endif
    }

    /// 指定された位置の被写体のみを切り抜いて背景を透明にする（長押し選択用）
    /// - Parameters:
    ///   - image: 元画像
    ///   - normalizedPoint: 画像座標系での正規化座標（0-1）
    static func removeBackgroundAtPoint(from image: UIImage, normalizedPoint: CGPoint) async throws -> BackgroundRemovalResult {
        let normalized = normalizeOrientation(image)
        #if targetEnvironment(simulator)
        let whiteMask = createWhiteMask(size: normalized.size)
        return BackgroundRemovalResult(processedImage: normalized, maskImage: whiteMask, originalImage: normalized)
        #else
        return try removeBackgroundAtPointReal(from: normalized, normalizedPoint: normalizedPoint)
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

    /// キャプチャフロー用の統合処理（Vision を1回だけ呼び出して分岐する）
    static func processForCapture(from image: UIImage) async throws -> CaptureProcessingResult {
        let normalized = normalizeOrientation(image)
        #if targetEnvironment(simulator)
        let whiteMask = createWhiteMask(size: normalized.size)
        return .singleSticker(BackgroundRemovalResult(processedImage: normalized, maskImage: whiteMask, originalImage: normalized))
        #else
        return try processForCaptureReal(from: normalized)
        #endif
    }

    private static func removeBackgroundAtPointReal(from image: UIImage, normalizedPoint: CGPoint) throws -> BackgroundRemovalResult {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemoverError.invalidImage
        }

        guard let (observation, handler) = try performInstanceMask(on: cgImage) else {
            throw BackgroundRemoverError.noSubjectAtPoint
        }

        // インスタンスマスクのピクセルバッファからタップ位置のインスタンスIDを取得
        let instanceMask = observation.instanceMask
        CVPixelBufferLockBaseAddress(instanceMask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(instanceMask, .readOnly) }

        let maskWidth = CVPixelBufferGetWidth(instanceMask)
        let maskHeight = CVPixelBufferGetHeight(instanceMask)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(instanceMask)

        guard let baseAddress = CVPixelBufferGetBaseAddress(instanceMask) else {
            throw BackgroundRemoverError.noSubjectAtPoint
        }

        let pixelX = max(0, min(Int(normalizedPoint.x * CGFloat(maskWidth)), maskWidth - 1))
        let pixelY = max(0, min(Int(normalizedPoint.y * CGFloat(maskHeight)), maskHeight - 1))

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let instanceIndex = Int(buffer[pixelY * bytesPerRow + pixelX])

        guard instanceIndex != 0, observation.allInstances.contains(instanceIndex) else {
            throw BackgroundRemoverError.noSubjectAtPoint
        }

        let selectedInstances = IndexSet(integer: instanceIndex)

        // 選択されたインスタンスのマスクを生成
        let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: selectedInstances, from: handler)
        let ciMask = CIImage(cvPixelBuffer: maskPixelBuffer)
        guard let maskCGImage = ciContext.createCGImage(ciMask, from: ciMask.extent) else {
            throw BackgroundRemoverError.renderFailed
        }
        let maskImage = UIImage(cgImage: maskCGImage)

        let processedImage = try applyMask(maskPixelBuffer: maskPixelBuffer, to: cgImage)

        return BackgroundRemovalResult(processedImage: processedImage, maskImage: maskImage, originalImage: image)
    }

    private static func removeBackgroundWithMaskReal(from image: UIImage) throws -> BackgroundRemovalResult {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemoverError.invalidImage
        }

        guard let (observation, handler) = try performInstanceMask(on: cgImage) else {
            let whiteMask = createWhiteMask(size: image.size)
            return BackgroundRemovalResult(processedImage: image, maskImage: whiteMask, originalImage: image)
        }

        // マスクを UIImage として取得
        let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler)
        let ciMask = CIImage(cvPixelBuffer: maskPixelBuffer)
        guard let maskCGImage = ciContext.createCGImage(ciMask, from: ciMask.extent) else {
            throw BackgroundRemoverError.renderFailed
        }
        let maskImage = UIImage(cgImage: maskCGImage)

        // 合成画像を生成（生成済みの maskPixelBuffer を再利用して二重計算を回避）
        let processedImage = try applyMask(maskPixelBuffer: maskPixelBuffer, to: cgImage)

        return BackgroundRemovalResult(processedImage: processedImage, maskImage: maskImage, originalImage: image)
    }

    private static func removeBackgroundReal(from image: UIImage) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemoverError.invalidImage
        }

        guard let (observation, handler) = try performInstanceMask(on: cgImage) else {
            return image
        }
        return try applyMask(observation, instances: observation.allInstances, to: cgImage, handler: handler)
    }

    private static func extractIndividualStickersReal(from image: UIImage) throws -> [UIImage] {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemoverError.invalidImage
        }

        guard let (observation, handler) = try performInstanceMask(on: cgImage) else {
            return [image]
        }
        let allInstances = observation.allInstances

        if allInstances.count <= 1 {
            let single = try applyMask(observation, instances: allInstances, to: cgImage, handler: handler)
            return [single]
        }

        return try extractInstanceImages(from: observation, handler: handler, instances: allInstances)
    }

    /// 指定されたインスタンスを1件ずつ切り抜いて UIImage 配列を返す。
    /// instances は空でないことを前提とする。全件レンダリング失敗した場合は noResult をスロー。
    private static func extractInstanceImages(
        from observation: VNInstanceMaskObservation,
        handler: VNImageRequestHandler,
        instances: IndexSet
    ) throws -> [UIImage] {
        var results: [UIImage] = []
        var failedCount = 0
        for instanceId in instances {
            let sticker: UIImage? = try autoreleasepool {
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
            if let sticker {
                results.append(sticker)
            } else {
                failedCount += 1
            }
        }

        if failedCount > 0 {
            print("[BackgroundRemover] extractInstanceImages: \(failedCount)件のインスタンスのレンダリングに失敗しました（成功: \(results.count)件）")
        }

        if results.isEmpty {
            throw BackgroundRemoverError.noResult
        }
        return results
    }

    private static func processForCaptureReal(from image: UIImage) throws -> CaptureProcessingResult {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemoverError.invalidImage
        }

        guard let (observation, handler) = try performInstanceMask(on: cgImage) else {
            // 被写体が検出されなかった場合、白マスクで単一シールとして返す
            let whiteMask = createWhiteMask(size: image.size)
            return .singleSticker(BackgroundRemovalResult(processedImage: image, maskImage: whiteMask, originalImage: image))
        }

        let allInstances = observation.allInstances

        guard !allInstances.isEmpty else {
            // Vision が observation を返したが被写体インスタンスがない場合は白マスクでフォールバック
            let whiteMask = createWhiteMask(size: image.size)
            return .singleSticker(BackgroundRemovalResult(processedImage: image, maskImage: whiteMask, originalImage: image))
        }

        if allInstances.count > 1 {
            let results = try extractInstanceImages(from: observation, handler: handler, instances: allInstances)
            return .multipleStickers(results)
        } else {
            // 単一被写体: マスク付きで返す（手動調整対応）
            let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: allInstances, from: handler)
            let ciMask = CIImage(cvPixelBuffer: maskPixelBuffer)
            guard let maskCGImage = ciContext.createCGImage(ciMask, from: ciMask.extent) else {
                throw BackgroundRemoverError.renderFailed
            }
            let maskImage = UIImage(cgImage: maskCGImage)

            let processedImage = try applyMask(maskPixelBuffer: maskPixelBuffer, to: cgImage)

            return .singleSticker(BackgroundRemovalResult(processedImage: processedImage, maskImage: maskImage, originalImage: image))
        }
    }

    private static func createWhiteMask(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    private static func performInstanceMask(on cgImage: CGImage) throws -> (VNInstanceMaskObservation, VNImageRequestHandler)? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let result = request.results?.first else {
            return nil
        }
        return (result, handler)
    }

    private static func applyMask(_ observation: VNInstanceMaskObservation, instances: IndexSet, to cgImage: CGImage, handler: VNImageRequestHandler) throws -> UIImage {
        let maskPixelBuffer = try observation.generateScaledMaskForImage(forInstances: instances, from: handler)
        return try applyMask(maskPixelBuffer: maskPixelBuffer, to: cgImage)
    }

    private static func applyMask(maskPixelBuffer: CVPixelBuffer, to cgImage: CGImage) throws -> UIImage {
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
    case noSubjectAtPoint

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "画像を読み込めませんでした"
        case .noResult: return "背景除去の結果を取得できませんでした"
        case .filterFailed: return "画像フィルタの適用に失敗しました"
        case .renderFailed: return "画像の生成に失敗しました"
        case .noSubjectAtPoint: return "選択した位置に被写体が見つかりませんでした。被写体の上を長押ししてください"
        }
    }
}
