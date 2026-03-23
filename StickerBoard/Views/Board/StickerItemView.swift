import SwiftUI

struct StickerItemView: View {
    @Binding var placement: StickerPlacement
    let image: UIImage?

    // ジェスチャー中の一時的な値
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
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "questionmark")
                        .foregroundStyle(.secondary)
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
