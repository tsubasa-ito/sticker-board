import SwiftUI

struct StickerPreviewView: View {
    let image: UIImage

    var body: some View {
        VStack(spacing: 8) {
            Text("切り抜き結果")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // チェッカーボード背景で透明部分を可視化
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .background {
                    CheckerboardBackground()
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
                .padding(.horizontal)
        }
    }
}

/// 透明部分を示すチェッカーボードパターン
struct CheckerboardBackground: View {
    let size: CGFloat = 10

    var body: some View {
        Canvas { context, canvasSize in
            let rows = Int(canvasSize.height / size) + 1
            let cols = Int(canvasSize.width / size) + 1

            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * size,
                        y: CGFloat(row) * size,
                        width: size,
                        height: size
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isLight ? .white : Color(.systemGray5))
                    )
                }
            }
        }
    }
}
