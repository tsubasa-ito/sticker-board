import SwiftUI

struct StickerPreviewView: View {
    let image: UIImage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 12) {
            // ラベル
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(AppTheme.softOrange)
                Text("切り抜き完了")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            // プレビュー画像
            ZStack {
                // チェッカーボード背景
                CheckerboardBackground()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(20)
            }
            .frame(maxHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppTheme.accent.opacity(0.2), lineWidth: 1)
            }
            .shadow(color: AppTheme.accent.opacity(0.15), radius: 16, y: 8)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                appeared = true
            }
        }
    }
}

struct CheckerboardBackground: View {
    let size: CGFloat = 12

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
                        with: .color(isLight ? AppTheme.checkerLight : AppTheme.checkerDark)
                    )
                }
            }
        }
    }
}
