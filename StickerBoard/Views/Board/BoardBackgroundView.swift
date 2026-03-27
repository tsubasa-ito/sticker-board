import SwiftUI

/// ボードの背景パターンを描画するビュー
struct BoardBackgroundView: View {
    let config: BackgroundPatternConfig
    /// カスタム背景画像（外部から注入、キャッシュ用）
    var customImage: UIImage?

    var body: some View {
        switch config.patternType {
        case .solid:
            solidBackground
        case .dot:
            dotBackground
        case .grid:
            gridBackground
        case .stripe:
            stripeBackground
        case .gradient:
            gradientBackground
        case .custom:
            customBackground
        }
    }

    // MARK: - 無地

    private var solidBackground: some View {
        Color(hexString: config.primaryColorHex)
    }

    // MARK: - ドット

    private var dotBackground: some View {
        Canvas { context, size in
            // ベース色
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(hexString: config.primaryColorHex))
            )

            let spacing: CGFloat = 20
            let dotSize: CGFloat = 3
            let dotColor = Color(hexString: config.secondaryColorHex)

            for x in stride(from: spacing / 2, to: size.width, by: spacing) {
                for y in stride(from: spacing / 2, to: size.height, by: spacing) {
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: x - dotSize / 2,
                            y: y - dotSize / 2,
                            width: dotSize,
                            height: dotSize
                        )),
                        with: .color(dotColor)
                    )
                }
            }
        }
    }

    // MARK: - グリッド

    private var gridBackground: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(hexString: config.primaryColorHex))
            )

            let spacing: CGFloat = 24
            let lineWidth: CGFloat = 0.5
            let lineColor = Color(hexString: config.secondaryColorHex)

            // 縦線
            for x in stride(from: spacing, to: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
            }

            // 横線
            for y in stride(from: spacing, to: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
            }
        }
    }

    // MARK: - ストライプ

    private var stripeBackground: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(hexString: config.primaryColorHex))
            )

            let stripeWidth: CGFloat = 12
            let gap: CGFloat = 12
            let stripeColor = Color(hexString: config.secondaryColorHex).opacity(0.3)
            let totalWidth = stripeWidth + gap
            // 斜めストライプ: 対角線をカバーするために十分な本数
            let diagonal = sqrt(size.width * size.width + size.height * size.height)
            let count = Int(diagonal / totalWidth) + 2

            for i in -count...count {
                let offset = CGFloat(i) * totalWidth
                var path = Path()
                path.move(to: CGPoint(x: offset, y: 0))
                path.addLine(to: CGPoint(x: offset + stripeWidth, y: 0))
                path.addLine(to: CGPoint(x: offset + stripeWidth + size.height, y: size.height))
                path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                path.closeSubpath()
                context.fill(path, with: .color(stripeColor))
            }
        }
    }

    // MARK: - グラデーション

    private var gradientBackground: some View {
        LinearGradient(
            colors: [
                Color(hexString: config.primaryColorHex),
                Color(hexString: config.secondaryColorHex),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - カスタム写真

    private var customBackground: some View {
        GeometryReader { geometry in
            if let image = customImage {
                let imageSize = image.size
                let containerSize = geometry.size
                let scale = max(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
                let scaledWidth = imageSize.width * scale
                let scaledHeight = imageSize.height * scale
                let cropX = config.customImageCropX ?? 0.5
                let cropY = config.customImageCropY ?? 0.5
                let offsetX = (0.5 - cropX) * (scaledWidth - containerSize.width)
                let offsetY = (0.5 - cropY) * (scaledHeight - containerSize.height)

                Image(uiImage: image)
                    .resizable()
                    .frame(width: scaledWidth, height: scaledHeight)
                    .offset(x: offsetX, y: offsetY)
                    .frame(width: containerSize.width, height: containerSize.height)
                    .clipped()
            } else {
                Color(hexString: config.primaryColorHex)
            }
        }
    }
}
