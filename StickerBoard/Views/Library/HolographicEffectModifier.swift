import SwiftUI
import UIKit

// MARK: - ホログラフィックカード効果（矩形カード用・ポケモンカード風）

/// サムネイルカードにホログラフィック効果を付与するModifier
/// 3D回転 + レインボーグラデーション + スペキュラハイライト
struct HolographicCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let intensity: Double

    private let motion = MotionManager.shared

    func body(content: Content) -> some View {
        let tiltX = motion.tiltX
        let tiltY = motion.tiltY
        let rotX = 8 * intensity * (tiltX - 0.5) * 2
        let rotY = -8 * intensity * (tiltY - 0.5) * 2

        content
            .overlay {
                ZStack {
                    cardRainbowSweep(tiltX: tiltX, tiltY: tiltY)
                    cardSpecularHighlight(tiltX: tiltX, tiltY: tiltY)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .allowsHitTesting(false)
            }
            .rotation3DEffect(.degrees(rotX), axis: (0, 1, 0), perspective: 0.8)
            .rotation3DEffect(.degrees(rotY), axis: (1, 0, 0), perspective: 0.8)
            .onAppear { motion.start() }
            .onDisappear { motion.stop() }
    }

    /// デバイスの傾きに追従する虹色グラデーション
    private func cardRainbowSweep(tiltX: Double, tiltY: Double) -> some View {
        let stops = rainbowStops(center: tiltX, opacity: 0.25 * intensity)
        let angle = 20 + (tiltY - 0.5) * 40
        return LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
            .rotationEffect(.degrees(angle))
            .blendMode(.overlay)
    }

    /// 傾きに追従する光沢ハイライト
    private func cardSpecularHighlight(tiltX: Double, tiltY: Double) -> some View {
        RadialGradient(
            colors: [
                .white.opacity(0.5 * intensity),
                .white.opacity(0.08 * intensity),
                .clear,
            ],
            center: UnitPoint(x: tiltX, y: tiltY),
            startRadius: 0,
            endRadius: 80
        )
        .blendMode(.overlay)
    }
}

// MARK: - ホログラフィックステッカー効果（自由形状シール用）

/// 自由形状のシール画像にホログラフィック効果を付与するModifier
/// シールのアルファチャンネルでマスクし、不透明部分のみに効果を適用
struct HolographicStickerModifier: ViewModifier {
    let image: UIImage?
    let intensity: Double
    let enableRotation: Bool

    private let motion = MotionManager.shared

    func body(content: Content) -> some View {
        let tiltX = motion.tiltX
        let tiltY = motion.tiltY
        let rotDegX = enableRotation ? 6 * intensity * (tiltX - 0.5) * 2 : 0
        let rotDegY = enableRotation ? -6 * intensity * (tiltY - 0.5) * 2 : 0

        content
            .overlay {
                if image != nil {
                    ZStack {
                        stickerRainbow(tiltX: tiltX, tiltY: tiltY)
                        stickerHighlight(tiltX: tiltX, tiltY: tiltY)
                    }
                    .mask {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .rotation3DEffect(.degrees(rotDegX), axis: (0, 1, 0), perspective: 0.8)
            .rotation3DEffect(.degrees(rotDegY), axis: (1, 0, 0), perspective: 0.8)
            .onAppear { motion.start() }
            .onDisappear { motion.stop() }
    }

    private func stickerRainbow(tiltX: Double, tiltY: Double) -> some View {
        let stops = rainbowStops(center: tiltX, opacity: 0.3 * intensity)
        let angle = 20 + (tiltY - 0.5) * 40
        return LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
            .rotationEffect(.degrees(angle))
            .blendMode(.colorDodge)
    }

    private func stickerHighlight(tiltX: Double, tiltY: Double) -> some View {
        RadialGradient(
            colors: [
                .white.opacity(0.5 * intensity),
                .white.opacity(0.1 * intensity),
                .clear,
            ],
            center: UnitPoint(x: tiltX, y: tiltY),
            startRadius: 0,
            endRadius: 150
        )
        .blendMode(.overlay)
    }
}

// MARK: - 共通ヘルパー

/// レインボーグラデーションのストップ配列を生成
private func rainbowStops(center: Double, opacity: Double) -> [Gradient.Stop] {
    let cyan = Color(hue: 0.52, saturation: 0.7, brightness: 1.0)
    let purple = Color(hue: 0.75, saturation: 0.8, brightness: 0.9)
    let magenta = Color(hue: 0.88, saturation: 0.7, brightness: 1.0)
    return [
        .init(color: .clear, location: max(0, center - 0.35)),
        .init(color: cyan.opacity(opacity), location: max(0, center - 0.12)),
        .init(color: purple.opacity(opacity * 0.8), location: center),
        .init(color: magenta.opacity(opacity), location: min(1, center + 0.12)),
        .init(color: .clear, location: min(1, center + 0.35)),
    ]
}

// MARK: - View Extensions

extension View {
    /// ホログラフィックカード効果を適用（矩形サムネイル用）
    func holographicCard(cornerRadius: CGFloat = 14, intensity: Double = 1.0) -> some View {
        modifier(HolographicCardModifier(cornerRadius: cornerRadius, intensity: intensity))
    }

    /// ホログラフィックステッカー効果を適用（自由形状シール用）
    func holographicSticker(
        image: UIImage?,
        intensity: Double = 0.6,
        enableRotation: Bool = true
    ) -> some View {
        modifier(HolographicStickerModifier(
            image: image,
            intensity: intensity,
            enableRotation: enableRotation
        ))
    }
}
