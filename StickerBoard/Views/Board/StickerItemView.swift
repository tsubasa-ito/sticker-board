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
                // タッチインジケーター
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.2))
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.6), lineWidth: 2)
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.accent)
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

    // MARK: - ジェスチャー

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                placement.positionX += value.translation.width
                placement.positionY += value.translation.height
                dragOffset = .zero
                onGestureEnded?()
            }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                currentScale = value.magnification
            }
            .onEnded { value in
                placement.scale *= value.magnification
                currentScale = 1.0
                onGestureEnded?()
            }
    }

    private var rotationGesture: some Gesture {
        RotateGesture()
            .onChanged { value in
                currentRotation = value.rotation
            }
            .onEnded { value in
                placement.rotation += value.rotation.radians
                currentRotation = .zero
                onGestureEnded?()
            }
    }
}
