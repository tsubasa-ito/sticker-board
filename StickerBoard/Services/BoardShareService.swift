import SwiftUI
import os

/// ボードのSNSシェア機能を提供するサービス
@MainActor
enum BoardShareService {
    private static let logger = Logger(subsystem: "com.tebasaki.StickerBoard", category: "Share")

    /// Board モデルから直接シェアシートを表示する（ホーム・ボード一覧から利用）
    static func share(_ board: Board, displayScale: CGFloat) {
        let customBackgroundImage = loadCustomBackgroundImage(for: board)
        presentShareSheet(
            placements: board.placements,
            canvasSize: estimatedCanvasSize(for: board),
            backgroundConfig: board.backgroundPattern,
            customBackgroundImage: customBackgroundImage,
            displayScale: displayScale
        )
    }

    /// エディタのキャンバスサイズを使ってシェアシートを表示する（ボードエディタから利用）
    static func share(placements: [StickerPlacement], canvasSize: CGSize, backgroundConfig: BackgroundPatternConfig, customBackgroundImage: UIImage?, displayScale: CGFloat) {
        presentShareSheet(
            placements: placements,
            canvasSize: canvasSize,
            backgroundConfig: backgroundConfig,
            customBackgroundImage: customBackgroundImage,
            displayScale: displayScale
        )
    }

    // MARK: - Private

    private static func presentShareSheet(placements: [StickerPlacement], canvasSize: CGSize, backgroundConfig: BackgroundPatternConfig, customBackgroundImage: UIImage?, displayScale: CGFloat) {
        let content = BoardSnapshotView(
            placements: placements,
            size: canvasSize,
            backgroundConfig: backgroundConfig,
            customBackgroundImage: customBackgroundImage,
            showWatermark: !SubscriptionManager.shared.isProUser
        )

        let renderer = ImageRenderer(content: content)
        renderer.scale = displayScale

        guard let image = renderer.uiImage else {
            logger.error("presentShareSheet: ImageRenderer returned nil (canvasSize=\(String(describing: canvasSize)))")
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

        // 最前面のVCを辿ってpresent（既存のシートやアラートと競合しないよう）
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        if let popover = activityVC.popoverPresentationController {
            let bounds = windowScene.screen.bounds
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        topVC.present(activityVC, animated: true)
    }

    /// Board の写真背景画像を読み込む（ファイル未発見時はログを出して nil を返す）
    private static func loadCustomBackgroundImage(for board: Board) -> UIImage? {
        guard board.backgroundPattern.patternType == .custom,
              let fileName = board.backgroundPattern.customImageFileName else { return nil }
        let image = BackgroundImageStorage.load(fileName: fileName)
        if image == nil {
            logger.error("loadCustomBackgroundImage: Failed to load '\(fileName)' for board \(board.id.uuidString)")
        }
        return image
    }

    /// BoardEditorView のキャンバスサイズを近似する（padding 24pt×2、ボードタイプ別アスペクト比）
    static func estimatedCanvasSize(for board: Board) -> CGSize {
        let bounds = AppTheme.screenBounds
        let width = bounds.width - 48
        switch board.boardType {
        case .widgetLarge:
            return CGSize(width: width, height: width / BoardType.widgetLargeAspectRatio)
        case .widgetMedium:
            return CGSize(width: width, height: width / BoardType.widgetMediumAspectRatio)
        case .standard:
            return CGSize(width: width, height: bounds.height - 200)
        }
    }
}
