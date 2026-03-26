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
            case .puffy:
                filtered = applyPuffy(to: ciImage)
            case .wappen:
                filtered = applyWappen(to: ciImage)
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

    // MARK: - ぷっくり（立体・膨らみエフェクト）

    private static func applyPuffy(to image: CIImage) -> CIImage? {
        let extent = image.extent
        let shortSide = min(extent.width, extent.height)

        guard let alphaMask = extractAlpha(from: image) else { return nil }

        // アルファマスクをぼかして「内側距離場」を生成
        // エッジ付近は値が低く、中央は高い → ぷっくり形状の断面を表現
        let edgeBlur = CIFilter.gaussianBlur()
        edgeBlur.inputImage = alphaMask
        edgeBlur.radius = Float(shortSide * 0.05)
        guard let blurredAlpha = edgeBlur.outputImage?.cropped(to: extent) else { return nil }

        // エッジ暗化: エッジ付近を暗くして立体感（陰影）を出す
        let darken = CIFilter.colorControls()
        darken.inputImage = image
        darken.brightness = -0.18
        darken.contrast = 1.1
        darken.saturation = 0.85
        guard let darkened = darken.outputImage else { return nil }

        // blurredAlpha をマスクとして合成
        // 中央（マスク白）→ 元画像、エッジ（マスク黒）→ 暗い画像
        let edgeBlend = CIFilter.blendWithMask()
        edgeBlend.inputImage = image
        edgeBlend.backgroundImage = darkened
        edgeBlend.maskImage = blurredAlpha
        guard let withEdge = edgeBlend.outputImage else { return nil }

        // スペキュラハイライト（ドーム表面の光沢反射）
        let hlCenter = CGPoint(x: extent.midX * 0.8, y: extent.maxY * 0.72)
        let specular = CIFilter.radialGradient()
        specular.center = hlCenter
        specular.radius0 = 0
        specular.radius1 = Float(shortSide * 0.28)
        specular.color0 = CIColor(red: 1, green: 1, blue: 1, alpha: 0.55)
        specular.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 0)
        guard let specGrad = specular.outputImage?.cropped(to: extent) else { return nil }

        // ハイライトを内側フィールドでマスク（エッジでは光沢が弱まる）
        let specMasked = CIFilter.blendWithMask()
        specMasked.inputImage = specGrad
        specMasked.backgroundImage = CIImage.empty()
        specMasked.maskImage = blurredAlpha
        guard let specResult = specMasked.outputImage else { return nil }

        // 合成（スクリーンブレンドで光沢を追加）
        let addSpec = CIFilter.screenBlendMode()
        addSpec.inputImage = specResult
        addSpec.backgroundImage = withEdge
        guard let result = addSpec.outputImage else { return nil }

        return applyAlphaMask(to: result, mask: alphaMask)
    }

    // MARK: - ワッペン（刺繍サテンステッチ風テクスチャ）

    /// サテンステッチ風タイルを生成してキャッシュ（密な横糸＋縦糸の交差）
    private static let fabricTile: CIImage? = {
        let tileSize: CGFloat = 80

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: tileSize, height: tileSize))
        let tileImage = renderer.image { ctx in
            let gc = ctx.cgContext

            // ベースを中間グレーで塗る
            gc.setFillColor(UIColor(white: 0.5, alpha: 1.0).cgColor)
            gc.fill(CGRect(x: 0, y: 0, width: tileSize, height: tileSize))

            // 密な横糸（サテンステッチ: 太い線を1.5px間隔で交互に明暗）
            let stitchSpacing: CGFloat = 1.5
            for (rowIndex, y) in stride(from: CGFloat(0), to: tileSize, by: stitchSpacing).enumerated() {
                let brightness: CGFloat = (rowIndex % 2 == 0) ? 0.62 : 0.38
                gc.setStrokeColor(UIColor(white: brightness, alpha: 1.0).cgColor)
                gc.setLineWidth(1.2)
                gc.move(to: CGPoint(x: 0, y: y))
                gc.addLine(to: CGPoint(x: tileSize, y: y))
                gc.strokePath()
            }

            // 縦糸（横糸より控えめだが存在感あり、織り目の交差を表現）
            let verticalStitchSpacing: CGFloat = 2.5
            for (colIndex, x) in stride(from: CGFloat(0), to: tileSize, by: verticalStitchSpacing).enumerated() {
                let brightness: CGFloat = (colIndex % 3 == 0) ? 0.35 : 0.55
                gc.setStrokeColor(UIColor(white: brightness, alpha: 0.3).cgColor)
                gc.setLineWidth(0.8)
                gc.move(to: CGPoint(x: x, y: 0))
                gc.addLine(to: CGPoint(x: x, y: tileSize))
                gc.strokePath()
            }
        }
        return CIImage(image: tileImage)
    }()

    private static func applyWappen(to image: CIImage) -> CIImage? {
        let extent = image.extent

        guard let alphaMask = extractAlpha(from: image) else { return nil }

        // 1. 彩度を落として糸に染めたような色合いに + わずかにコントラスト低下
        let colorAdjust = CIFilter.colorControls()
        colorAdjust.inputImage = image
        colorAdjust.saturation = 0.7
        colorAdjust.brightness = 0.0
        colorAdjust.contrast = 0.85
        guard let adjusted = colorAdjust.outputImage else { return nil }

        // 2. サテンステッチテクスチャを敷き詰めてオーバーレイ
        guard let tile = fabricTile else { return nil }

        let tiled = tile.applyingFilter("CIAffineTile", parameters: [
            "inputTransform": NSValue(cgAffineTransform: .identity),
        ]).cropped(to: extent)

        // テクスチャをオーバーレイブレンド（元画像の明暗に沿ってステッチが乗る）
        let texBlend = CIFilter.overlayBlendMode()
        texBlend.inputImage = tiled
        texBlend.backgroundImage = adjusted
        guard let textured = texBlend.outputImage else { return nil }

        // 3. ランダムノイズで糸の微妙な色ムラを追加
        let noise = CIFilter.randomGenerator()
        guard let noiseOutput = noise.outputImage?.cropped(to: extent) else { return nil }

        let noiseOpacity = CIFilter.colorMatrix()
        noiseOpacity.inputImage = noiseOutput
        noiseOpacity.rVector = CIVector(x: 0.06, y: 0, z: 0, w: 0)
        noiseOpacity.gVector = CIVector(x: 0, y: 0.06, z: 0, w: 0)
        noiseOpacity.bVector = CIVector(x: 0, y: 0, z: 0.06, w: 0)
        noiseOpacity.aVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        noiseOpacity.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0.15)
        guard let subtleNoise = noiseOpacity.outputImage else { return nil }

        let noiseBlend = CIFilter.sourceOverCompositing()
        noiseBlend.inputImage = subtleNoise
        noiseBlend.backgroundImage = textured
        guard let withNoise = noiseBlend.outputImage else { return nil }

        // 4. エンボス効果（刺繍の糸の凹凸感を強調）
        let embossWeights: [CGFloat] = [
            -1,   -0.5,  0,
            -0.5,  1,    0.5,
             0,    0.5,  1,
        ]
        let convolution = CIFilter.convolution3X3()
        convolution.inputImage = withNoise
        convolution.weights = CIVector(values: embossWeights, count: 9)
        convolution.bias = 0.0
        guard let embossed = convolution.outputImage?.cropped(to: extent) else { return nil }

        // エンボスをソフトライトで合成（糸の立体感）
        let embossBlend = CIFilter.softLightBlendMode()
        embossBlend.inputImage = embossed
        embossBlend.backgroundImage = withNoise
        guard let withEmboss = embossBlend.outputImage else { return nil }

        // 5. わずかにシャープネスを上げて糸のディテールを際立たせる
        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = withEmboss
        sharpen.sharpness = 0.6
        sharpen.radius = 1.0
        guard let sharpened = sharpen.outputImage else { return nil }

        return applyAlphaMask(to: sharpened, mask: alphaMask)
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
