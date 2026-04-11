import Photos
import UIKit
import os

/// シール単体の共有・写真保存機能を提供するサービス
@MainActor
enum StickerShareService {
    private static let logger = Logger(subsystem: "com.tebasaki.StickerBoard", category: "StickerShare")

    /// シール画像をシェアシートで共有する
    static func share(_ sticker: Sticker) {
        Task {
            await presentShareSheet(for: sticker)
        }
    }

    /// シール画像をフォトライブラリに保存する
    /// - Returns: 保存成功時は true、失敗時は false
    static func saveToPhotos(_ sticker: Sticker) async -> Bool {
        guard let image = await loadImage(for: sticker) else {
            logger.error("saveToPhotos: Failed to load image for sticker \(sticker.imageFileName)")
            return false
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            logger.warning("saveToPhotos: Photo library authorization denied (status=\(status.rawValue))")
            return false
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            return true
        } catch {
            logger.error("saveToPhotos: Failed to save to photo library: \(error)")
            return false
        }
    }

    // MARK: - Private

    private static func presentShareSheet(for sticker: Sticker) async {
        guard let image = await loadImage(for: sticker) else {
            logger.error("presentShareSheet: Failed to load image for sticker \(sticker.imageFileName)")
            return
        }

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.keyWindow?.rootViewController else {
            logger.error("presentShareSheet: Could not find foreground window scene or rootViewController")
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }

        topVC.present(activityVC, animated: true)
    }

    private static func loadImage(for sticker: Sticker) async -> UIImage? {
        let fileName = sticker.imageFileName
        return await Task.detached {
            ImageStorage.load(fileName: fileName)
        }.value
    }
}
