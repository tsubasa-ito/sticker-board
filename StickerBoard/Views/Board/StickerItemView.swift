import SwiftUI

struct StickerItemView: View {
    @Binding var placement: StickerPlacement
    let image: UIImage?
    var isSelected: Bool = false
    var onTap: (() -> Void)?
    var onGestureEnded: (() -> Void)?

    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero

    var body: some View {
        stickerContent
            .scaleEffect(placement.scale * currentScale)
            .rotationEffect(.radians(placement.rotation) + currentRotation)
            .offset(x: placement.positionX + dragOffset.width,
                    y: placement.positionY + dragOffset.height)
            .gesture(dragGesture)
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(rotationGesture)
            .simultaneousGesture(TapGesture().onEnded { onTap?() })
            .modifier(StickerAccessibilityModifier(
                placement: $placement,
                isSelected: isSelected,
                accessibilityDescription: accessibilityDescription,
                onTap: onTap,
                onGestureEnded: onGestureEnded,
                moveSticker: moveSticker,
                resizeSticker: resizeSticker,
                rotateSticker: rotateSticker
            ))
    }

    // MARK: - コンテンツ

    @ViewBuilder
    private var stickerContent: some View {
        ZStack(alignment: .topTrailing) {
            stickerImage
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.accent, lineWidth: 3)
                            .padding(-6)
                    }
                }

            if isSelected {
                // 選択インジケーター（ロック中は南京錠アイコン）
                ZStack {
                    Circle()
                        .fill(placement.isLocked ? AppTheme.textSecondary.opacity(0.2) : AppTheme.accent.opacity(0.2))
                    Circle()
                        .stroke(placement.isLocked ? AppTheme.textSecondary.opacity(0.6) : AppTheme.accent.opacity(0.6), lineWidth: 2)
                    Image(systemName: placement.isLocked ? "lock.fill" : "hand.tap.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(placement.isLocked ? AppTheme.textSecondary : AppTheme.accent)
                }
                .frame(width: 32, height: 32)
                .offset(x: 12, y: -12)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    @ViewBuilder
    private var stickerImage: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .holographicSticker(image: image, intensity: 0.4, enableRotation: false)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.backgroundCard)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("読込失敗")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
    }

    // MARK: - アクセシビリティ

    private var accessibilityDescription: String {
        let x = Int(placement.positionX)
        let y = Int(placement.positionY)
        let scale = Int(placement.scale * 100)
        let degrees = Int(placement.rotation * 180 / .pi)
        let lockState = placement.isLocked ? "、ロック中" : ""
        return "位置: \(x), \(y)、サイズ: \(scale)%、回転: \(degrees)°\(lockState)"
    }

    private func moveSticker(dx: CGFloat, dy: CGFloat) {
        placement.positionX += dx
        placement.positionY += dy
        onGestureEnded?()
        UIAccessibility.post(notification: .announcement, argument: "位置: \(Int(placement.positionX)), \(Int(placement.positionY))")
    }

    private func resizeSticker(factor: CGFloat) {
        placement.scale *= factor
        onGestureEnded?()
        UIAccessibility.post(notification: .announcement, argument: "サイズ: \(Int(placement.scale * 100))%")
    }

    private func rotateSticker(degrees: Double) {
        placement.rotation += degrees * .pi / 180
        onGestureEnded?()
        UIAccessibility.post(notification: .announcement, argument: "回転: \(Int(placement.rotation * 180 / .pi))°")
    }

    // MARK: - ジェスチャー

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !placement.isLocked else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !placement.isLocked else {
                    dragOffset = .zero
                    return
                }
                placement.positionX += value.translation.width
                placement.positionY += value.translation.height
                dragOffset = .zero
                onGestureEnded?()
            }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                guard !placement.isLocked else { return }
                currentScale = value.magnification
            }
            .onEnded { value in
                guard !placement.isLocked else {
                    currentScale = 1.0
                    return
                }
                placement.scale *= value.magnification
                currentScale = 1.0
                onGestureEnded?()
            }
    }

    private var rotationGesture: some Gesture {
        RotateGesture()
            .onChanged { value in
                guard !placement.isLocked else { return }
                currentRotation = value.rotation
            }
            .onEnded { value in
                guard !placement.isLocked else {
                    currentRotation = .zero
                    return
                }
                placement.rotation += value.rotation.radians
                currentRotation = .zero
                onGestureEnded?()
            }
    }
}

// MARK: - アクセシビリティ修飾子

private struct StickerAccessibilityModifier: ViewModifier {
    @Binding var placement: StickerPlacement
    let isSelected: Bool
    let accessibilityDescription: String
    let onTap: (() -> Void)?
    let onGestureEnded: (() -> Void)?
    let moveSticker: (CGFloat, CGFloat) -> Void
    let resizeSticker: (CGFloat) -> Void
    let rotateSticker: (Double) -> Void

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("シール")
            .accessibilityValue(accessibilityDescription)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityAction(named: "選択") { onTap?() }
            .accessibilityAction(named: placement.isLocked ? "ロック解除" : "ロック") {
                placement.isLocked.toggle()
                onGestureEnded?()
            }
            .accessibilityAction(named: "上に移動") { if !placement.isLocked { moveSticker(0, -20) } }
            .accessibilityAction(named: "下に移動") { if !placement.isLocked { moveSticker(0, 20) } }
            .accessibilityAction(named: "左に移動") { if !placement.isLocked { moveSticker(-20, 0) } }
            .accessibilityAction(named: "右に移動") { if !placement.isLocked { moveSticker(20, 0) } }
            .accessibilityAction(named: "拡大") { if !placement.isLocked { resizeSticker(1.1) } }
            .accessibilityAction(named: "縮小") { if !placement.isLocked { resizeSticker(0.9) } }
            .accessibilityAction(named: "時計回りに回転") { if !placement.isLocked { rotateSticker(15) } }
            .accessibilityAction(named: "反時計回りに回転") { if !placement.isLocked { rotateSticker(-15) } }
    }
}
