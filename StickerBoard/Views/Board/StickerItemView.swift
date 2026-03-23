import SwiftUI

struct StickerItemView: View {
    @Binding var placement: StickerPlacement
    let image: UIImage?

    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero

    var body: some View {
        stickerImage
            .scaleEffect(placement.scale * currentScale)
            .rotationEffect(.radians(placement.rotation) + currentRotation)
            .offset(x: placement.positionX + dragOffset.width,
                    y: placement.positionY + dragOffset.height)
            .gesture(dragGesture)
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(rotationGesture)
    }

    @ViewBuilder
    private var stickerImage: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        } else {
            // プレースホルダー（見えるように改善）
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
            }
    }
}
