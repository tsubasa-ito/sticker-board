import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

// MARK: - ブラシモード

enum BrushMode {
    case eraser   // 消しゴム（マスクを黒 = 透明に）
    case restore  // 復元（マスクを白 = 不透明に）
}

// MARK: - MaskDrawingCanvas（UIViewRepresentable）

// MARK: - キャンバスデリゲート

protocol MaskCanvasDelegate: AnyObject {
    func canvasStrokeStarted()
    func canvasStrokeCompleted(mask: UIImage)
}

struct MaskDrawingCanvas: UIViewRepresentable {
    let originalImage: UIImage
    @Binding var currentMask: UIImage
    @Binding var brushMode: BrushMode
    @Binding var brushSize: CGFloat
    var onStrokeStarted: () -> Void
    var onStrokeCompleted: (UIImage) -> Void

    func makeUIView(context: Context) -> MaskCanvasContainerView {
        let container = MaskCanvasContainerView(
            originalImage: originalImage,
            initialMask: currentMask,
            coordinator: context.coordinator
        )
        context.coordinator.container = container
        return container
    }

    func updateUIView(_ container: MaskCanvasContainerView, context: Context) {
        context.coordinator.brushMode = brushMode
        context.coordinator.brushSize = brushSize
        container.canvasView.updateMask(currentMask)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            brushMode: brushMode,
            brushSize: brushSize,
            onStrokeStarted: onStrokeStarted,
            onStrokeCompleted: onStrokeCompleted
        )
    }

    class Coordinator: NSObject, UIScrollViewDelegate, MaskCanvasDelegate {
        var brushMode: BrushMode
        var brushSize: CGFloat
        private let onStrokeStarted: () -> Void
        private let onStrokeCompleted: (UIImage) -> Void
        weak var container: MaskCanvasContainerView?

        init(brushMode: BrushMode, brushSize: CGFloat,
             onStrokeStarted: @escaping () -> Void,
             onStrokeCompleted: @escaping (UIImage) -> Void) {
            self.brushMode = brushMode
            self.brushSize = brushSize
            self.onStrokeStarted = onStrokeStarted
            self.onStrokeCompleted = onStrokeCompleted
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            container?.contentView
        }

        // MARK: - MaskCanvasDelegate

        func canvasStrokeStarted() {
            onStrokeStarted()
        }

        func canvasStrokeCompleted(mask: UIImage) {
            onStrokeCompleted(mask)
        }
    }
}

// MARK: - コンテナビュー（UIScrollView + Canvas）

class MaskCanvasContainerView: UIView {
    let scrollView: UIScrollView
    let contentView: UIView
    let originalImageView: UIImageView
    let maskOverlayView: MaskOverlayView
    let canvasView: MaskCanvasUIView
    private let imageSize: CGSize

    init(originalImage: UIImage, initialMask: UIImage, coordinator: MaskDrawingCanvas.Coordinator) {
        let imgSize = originalImage.size
        self.imageSize = imgSize

        scrollView = UIScrollView()
        contentView = UIView(frame: CGRect(origin: .zero, size: imgSize))

        // 元画像表示
        originalImageView = UIImageView(image: originalImage)
        originalImageView.frame = CGRect(origin: .zero, size: imgSize)
        originalImageView.contentMode = .scaleToFill

        // マスクオーバーレイ（消去部分を赤く表示）
        maskOverlayView = MaskOverlayView(frame: CGRect(origin: .zero, size: imgSize))

        // 描画キャンバス
        canvasView = MaskCanvasUIView(
            imageSize: imgSize,
            initialMask: initialMask,
            coordinator: coordinator
        )
        canvasView.frame = CGRect(origin: .zero, size: imgSize)

        super.init(frame: .zero)

        // チェッカーボード背景
        let checkerboard = CheckerboardUIView(frame: CGRect(origin: .zero, size: imgSize))
        contentView.addSubview(checkerboard)
        contentView.addSubview(originalImageView)
        contentView.addSubview(maskOverlayView)
        contentView.addSubview(canvasView)

        scrollView.addSubview(contentView)
        scrollView.delegate = coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        // 2本指でパン（1本指は描画用）
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2

        addSubview(scrollView)

        canvasView.maskOverlayView = maskOverlayView
        if let cgMask = initialMask.cgImage {
            maskOverlayView.updateMask(cgMask)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds

        let viewSize = bounds.size
        guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0 else { return }

        // 画像をビューにフィットさせるスケール
        let fitScale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let contentSize = CGSize(width: imageSize.width * fitScale, height: imageSize.height * fitScale)

        contentView.transform = .identity
        contentView.frame = CGRect(origin: .zero, size: imageSize)
        scrollView.contentSize = contentSize

        // fitScale を minimumZoomScale として設定
        scrollView.minimumZoomScale = fitScale
        scrollView.maximumZoomScale = fitScale * 5.0
        scrollView.zoomScale = fitScale

        centerContent()
    }

    private func centerContent() {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }
}

// MARK: - マスクオーバーレイビュー

class MaskOverlayView: UIView {
    private var cachedInvertedMask: CGImage?
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private let invertFilter = CIFilter.colorInvert()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateMask(_ mask: CGImage) {
        cachedInvertedMask = invertMask(mask)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(),
              let invertedMask = cachedInvertedMask else { return }

        ctx.saveGState()
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1, y: -1)
        ctx.clip(to: bounds, mask: invertedMask)
        ctx.setFillColor(UIColor.red.withAlphaComponent(0.35).cgColor)
        ctx.fill(bounds)
        ctx.restoreGState()
    }

    private func invertMask(_ mask: CGImage) -> CGImage? {
        invertFilter.inputImage = CIImage(cgImage: mask)
        guard let output = invertFilter.outputImage else { return nil }
        return Self.ciContext.createCGImage(output, from: output.extent)
    }
}

// MARK: - 描画キャンバスビュー

class MaskCanvasUIView: UIView {
    private var maskContext: CGContext?
    private let imageSize: CGSize
    private weak var delegate: MaskCanvasDelegate?
    private weak var coordinator: MaskDrawingCanvas.Coordinator?
    weak var maskOverlayView: MaskOverlayView?
    private var lastPoint: CGPoint?
    private var isExternalUpdate = false

    init(imageSize: CGSize, initialMask: UIImage, coordinator: MaskDrawingCanvas.Coordinator) {
        self.imageSize = imageSize
        self.coordinator = coordinator
        self.delegate = coordinator
        super.init(frame: CGRect(origin: .zero, size: imageSize))
        backgroundColor = .clear
        isMultipleTouchEnabled = false

        isAccessibilityElement = true
        accessibilityLabel = String(localized: "マスク描画キャンバス")
        accessibilityTraits = .allowsDirectInteraction
        accessibilityHint = String(localized: "指でなぞってマスクを編集します。2本指でズームやスクロールができます")

        setupMaskContext(with: initialMask)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMaskContext(with mask: UIImage) {
        let width = Int(imageSize.width)
        let height = Int(imageSize.height)
        guard width > 0, height > 0 else { return }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        maskContext = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )

        guard let ctx = maskContext, let cgMask = mask.cgImage else { return }
        ctx.draw(cgMask, in: CGRect(x: 0, y: 0, width: width, height: height))
    }

    func updateMask(_ mask: UIImage) {
        guard !isExternalUpdate else { return }
        isExternalUpdate = true
        setupMaskContext(with: mask)
        if let cgImage = maskContext?.makeImage() {
            maskOverlayView?.updateMask(cgImage)
        }
        isExternalUpdate = false
    }

    // MARK: - タッチハンドリング

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        lastPoint = point
        delegate?.canvasStrokeStarted()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let ctx = maskContext else { return }

        let brushRadius = coordinator?.brushSize ?? 30
        let isEraser = coordinator?.brushMode == .eraser
        let viewToImageX = imageSize.width / bounds.width
        let viewToImageY = imageSize.height / bounds.height
        let imgBrushRadius = brushRadius * viewToImageX
        let grayValue: CGFloat = isEraser ? 0.0 : 1.0
        ctx.setFillColor(gray: grayValue, alpha: 1.0)

        // coalescedTouches で間引かれたタッチポイントをすべて処理しストロークを滑らかにする
        let touchesToProcess = event?.coalescedTouches(for: touch) ?? [touch]
        for coalescedTouch in touchesToProcess {
            let currentPoint = coalescedTouch.location(in: self)
            let previousPoint = lastPoint ?? currentPoint

            let imgPrevious = CGPoint(x: previousPoint.x * viewToImageX, y: (bounds.height - previousPoint.y) * viewToImageY)
            let imgCurrent = CGPoint(x: currentPoint.x * viewToImageX, y: (bounds.height - currentPoint.y) * viewToImageY)

            let distance = hypot(imgCurrent.x - imgPrevious.x, imgCurrent.y - imgPrevious.y)
            let step = max(imgBrushRadius * 0.3, 1.0)
            let steps = max(Int(distance / step), 1)

            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let x = imgPrevious.x + (imgCurrent.x - imgPrevious.x) * t
                let y = imgPrevious.y + (imgCurrent.y - imgPrevious.y) * t
                ctx.fillEllipse(in: CGRect(x: x - imgBrushRadius, y: y - imgBrushRadius,
                                           width: imgBrushRadius * 2, height: imgBrushRadius * 2))
            }

            lastPoint = currentPoint
        }

        // 直接更新することでタッチ→描画反映のレイテンシをゼロにする
        updateOverlayFromMask()
    }

    private func updateOverlayFromMask() {
        guard let cgImage = maskContext?.makeImage() else { return }
        maskOverlayView?.updateMask(cgImage)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastPoint = nil
        if let cgImage = maskContext?.makeImage() {
            maskOverlayView?.updateMask(cgImage)
            delegate?.canvasStrokeCompleted(mask: UIImage(cgImage: cgImage))
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - マスク画像取得

    func getCurrentMaskImage() -> UIImage? {
        guard let cgImage = maskContext?.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - チェッカーボード背景（UIKit版）

class CheckerboardUIView: UIView {
    private let squareSize: CGFloat = 12

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let lightColor = UIColor(white: 0.95, alpha: 1.0).cgColor
        let darkColor = UIColor(white: 0.85, alpha: 1.0).cgColor

        let cols = Int(ceil(bounds.width / squareSize))
        let rows = Int(ceil(bounds.height / squareSize))

        for row in 0..<rows {
            for col in 0..<cols {
                let isLight = (row + col) % 2 == 0
                ctx.setFillColor(isLight ? lightColor : darkColor)
                ctx.fill(CGRect(x: CGFloat(col) * squareSize, y: CGFloat(row) * squareSize,
                                width: squareSize, height: squareSize))
            }
        }
    }
}
