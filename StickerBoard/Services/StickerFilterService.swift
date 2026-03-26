import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct StickerFilterService {

    private static let ciContext = CIContext()

    /// フィルターを適用した画像を返す
    static func apply(_ filter: StickerFilter, to image: UIImage) -> UIImage {
        guard filter != .original else { return image }

        return autoreleasepool {
            guard let ciImage = CIImage(image: image) else { return image }

            let filtered: CIImage?
            switch filter {
            case .original:
                return image
            case .sparkle:
                filtered = applySparkle(to: ciImage)
            case .retro:
                filtered = applyRetro(to: ciImage)
            case .pastel:
                filtered = applyPastel(to: ciImage)
            case .neon:
                filtered = applyNeon(to: ciImage)
            }

            guard let output = filtered,
                  let cgImage = ciContext.createCGImage(output, from: ciImage.extent) else {
                return image
            }
            return UIImage(cgImage: cgImage)
        }
    }

    // MARK: - キラキラ（ホログラムシール風オーバーレイ）

    /// 小さなタイルを1枚だけ生成してキャッシュ（メモリ節約）
    private static let hologramTile: CIImage? = {
        let cellSize: CGFloat = 30
        let gridCount = 6
        let tileSize = cellSize * CGFloat(gridCount)

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: tileSize, height: tileSize))
        let tileImage = renderer.image { ctx in
            let gc = ctx.cgContext
            for row in 0..<gridCount {
                for col in 0..<gridCount {
                    let hue = CGFloat(col + row) / CGFloat(gridCount * 2)
                    let x = CGFloat(col) * cellSize
                    let y = CGFloat(row) * cellSize
                    let cx = x + cellSize / 2
                    let cy = y + cellSize / 2

                    let faces: [(CGPoint, CGPoint, CGFloat, CGFloat, CGFloat)] = [
                        (CGPoint(x: x, y: y), CGPoint(x: x + cellSize, y: y), hue, 0.35, 1.0),
                        (CGPoint(x: x + cellSize, y: y), CGPoint(x: x + cellSize, y: y + cellSize), hue + 0.08, 0.45, 0.95),
                        (CGPoint(x: x + cellSize, y: y + cellSize), CGPoint(x: x, y: y + cellSize), hue + 0.15, 0.5, 0.85),
                        (CGPoint(x: x, y: y + cellSize), CGPoint(x: x, y: y), hue + 0.22, 0.4, 0.9),
                    ]
                    for (p1, p2, h, s, b) in faces {
                        gc.setFillColor(UIColor(hue: h, saturation: s, brightness: b, alpha: 1.0).cgColor)
                        gc.move(to: p1)
                        gc.addLine(to: p2)
                        gc.addLine(to: CGPoint(x: cx, y: cy))
                        gc.closePath()
                        gc.fillPath()
                    }
                }
            }
        }
        return CIImage(image: tileImage)
    }()

    private static func applySparkle(to image: CIImage) -> CIImage? {
        let extent = image.extent

        guard let alphaMask = extractAlpha(from: image) else { return nil }
        guard let tile = hologramTile else { return nil }

        // タイルを繰り返して画像全体に敷き詰める
        let tiled = tile.applyingFilter("CIAffineTile", parameters: [
            "inputTransform": NSValue(cgAffineTransform: .identity),
        ]).cropped(to: extent)

        // 半透明にして元画像とオーバーレイ合成
        let opacity = CIFilter.colorMatrix()
        opacity.inputImage = tiled
        opacity.rVector = CIVector(x: 1, y: 0, z: 0, w: 0)
        opacity.gVector = CIVector(x: 0, y: 1, z: 0, w: 0)
        opacity.bVector = CIVector(x: 0, y: 0, z: 1, w: 0)
        opacity.aVector = CIVector(x: 0, y: 0, z: 0, w: 0.35)
        opacity.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        guard let semiTransparent = opacity.outputImage else { return nil }

        let blend = CIFilter.sourceOverCompositing()
        blend.inputImage = semiTransparent
        blend.backgroundImage = image
        guard let blended = blend.outputImage else { return nil }

        return applyAlphaMask(to: blended, mask: alphaMask)
    }

    // MARK: - レトロ（セピア＋粒子感）

    private static func applyRetro(to image: CIImage) -> CIImage? {
        let extent = image.extent

        guard let alphaMask = extractAlpha(from: image) else { return nil }

        // セピアトーン
        let sepia = CIFilter.sepiaTone()
        sepia.inputImage = image
        sepia.intensity = 0.75
        guard let sepiaOutput = sepia.outputImage else { return nil }

        // ビネット効果（周辺減光）
        let vignette = CIFilter.vignette()
        vignette.inputImage = sepiaOutput
        vignette.intensity = 0.8
        vignette.radius = 1.5
        guard let vignetteOutput = vignette.outputImage else { return nil }

        // 粒子ノイズの追加
        let noise = CIFilter.randomGenerator()
        guard let noiseOutput = noise.outputImage?.cropped(to: extent) else { return nil }

        // ノイズを半透明モノクロに変換
        let monoNoise = CIFilter.colorMatrix()
        monoNoise.inputImage = noiseOutput
        monoNoise.rVector = CIVector(x: 0.1, y: 0, z: 0, w: 0)
        monoNoise.gVector = CIVector(x: 0, y: 0.1, z: 0, w: 0)
        monoNoise.bVector = CIVector(x: 0, y: 0, z: 0.1, w: 0)
        monoNoise.aVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        monoNoise.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0.12)
        guard let grainNoise = monoNoise.outputImage else { return nil }

        // ノイズをソフトに
        let blurNoise = CIFilter.gaussianBlur()
        blurNoise.inputImage = grainNoise
        blurNoise.radius = 0.5
        guard let softNoise = blurNoise.outputImage?.cropped(to: extent) else { return nil }

        // 合成
        let composite = CIFilter.sourceOverCompositing()
        composite.inputImage = softNoise
        composite.backgroundImage = vignetteOutput
        guard let result = composite.outputImage else { return nil }

        return applyAlphaMask(to: result, mask: alphaMask)
    }

    // MARK: - パステル（彩度を下げて柔らかいトーン）

    private static func applyPastel(to image: CIImage) -> CIImage? {
        guard let alphaMask = extractAlpha(from: image) else { return nil }

        // 彩度を下げ、明度を少し上げる
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = image
        colorControls.saturation = 0.45
        colorControls.brightness = 0.08
        colorControls.contrast = 0.85
        guard let adjusted = colorControls.outputImage else { return nil }

        // ほんのりピンクティント
        let tint = CIFilter.colorMatrix()
        tint.inputImage = adjusted
        tint.rVector = CIVector(x: 1.0, y: 0, z: 0, w: 0)
        tint.gVector = CIVector(x: 0, y: 0.95, z: 0, w: 0)
        tint.bVector = CIVector(x: 0, y: 0, z: 0.98, w: 0)
        tint.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        tint.biasVector = CIVector(x: 0.03, y: 0.01, z: 0.02, w: 0)
        guard let tinted = tint.outputImage else { return nil }

        return applyAlphaMask(to: tinted, mask: alphaMask)
    }

    // MARK: - ネオン（エッジグロー効果）

    private static func applyNeon(to image: CIImage) -> CIImage? {
        let extent = image.extent

        guard let alphaMask = extractAlpha(from: image) else { return nil }

        // エッジ検出
        let edges = CIFilter.edges()
        edges.inputImage = image
        edges.intensity = 5.0
        guard let edgeOutput = edges.outputImage else { return nil }

        // エッジの色を鮮やかに（シアン〜マゼンタのネオン調）
        let edgeColor = CIFilter.colorControls()
        edgeColor.inputImage = edgeOutput
        edgeColor.saturation = 2.5
        edgeColor.brightness = 0.3
        edgeColor.contrast = 1.5
        guard let coloredEdge = edgeColor.outputImage else { return nil }

        // グロー（ぼかし）
        let glow = CIFilter.gaussianBlur()
        glow.inputImage = coloredEdge
        glow.radius = 4.0
        guard let glowOutput = glow.outputImage?.cropped(to: extent) else { return nil }

        // エッジ + グローを加算合成
        let addEdges = CIFilter.additionCompositing()
        addEdges.inputImage = coloredEdge
        addEdges.backgroundImage = glowOutput
        guard let brightEdges = addEdges.outputImage else { return nil }

        // 元画像を少し暗くしてコントラストを強調
        let darken = CIFilter.colorControls()
        darken.inputImage = image
        darken.brightness = -0.05
        darken.contrast = 1.15
        darken.saturation = 1.2
        guard let darkenedImage = darken.outputImage else { return nil }

        // エッジを元画像にスクリーン合成
        let blend = CIFilter.screenBlendMode()
        blend.inputImage = brightEdges
        blend.backgroundImage = darkenedImage
        guard let result = blend.outputImage else { return nil }

        return applyAlphaMask(to: result, mask: alphaMask)
    }

    // MARK: - アルファチャンネル操作

    /// 画像からアルファチャンネルをグレースケール画像として抽出
    private static func extractAlpha(from image: CIImage) -> CIImage? {
        // アルファチャンネルを R チャンネルにコピー
        let alphaFilter = CIFilter.colorMatrix()
        alphaFilter.inputImage = image
        alphaFilter.rVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaFilter.gVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaFilter.bVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaFilter.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        alphaFilter.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        return alphaFilter.outputImage
    }

    /// フィルター適用後の画像に元のアルファマスクを適用
    private static func applyAlphaMask(to image: CIImage, mask: CIImage) -> CIImage? {
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = image
        blendFilter.backgroundImage = CIImage.empty()
        blendFilter.maskImage = mask
        return blendFilter.outputImage
    }
}
