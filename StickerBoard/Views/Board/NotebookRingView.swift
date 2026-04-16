import SwiftUI

/// クリアバインダー手帳のリング列ビュー
/// シルバー/クロームの金属リングと透明感のあるスパイン
struct NotebookRingView: View {

    var body: some View {
        GeometryReader { geo in
            ZStack {
                spineBackground(size: geo.size)
                ringsLayer(in: geo.size)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - スパイン（綴じ具の背景）

    private func spineBackground(size: CGSize) -> some View {
        ZStack {
            // ベース：フロスト感のある半透明グレー
            Rectangle()
                .fill(AppTheme.notebookSpine.opacity(0.85))

            // 左エッジハイライト（光の当たり感）
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.45), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 3)
                Spacer()
            }

            // 右エッジシャドウ（ページとの境界）
            HStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.08)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 4)
            }

            // 縦のすじ（透明プラスチックの質感）
            HStack {
                Spacer()
                    .frame(width: size.width * 0.4)
                Rectangle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 1)
                Spacer()
            }
        }
    }

    // MARK: - リング群

    private func ringsLayer(in size: CGSize) -> some View {
        let count = ringCount(for: size.height)
        let spacing = ringSpacing(height: size.height, count: count)

        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                ring
                    .position(
                        x: size.width / 2,
                        y: 22 + CGFloat(i) * spacing
                    )
            }
        }
    }

    // MARK: - 個別リング（シルバー/クロームO字リング）

    private var ring: some View {
        let outer: CGFloat = 22
        let inner: CGFloat = 12   // 穴の直径

        return ZStack {
            // リングドロップシャドウ
            Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: outer, height: outer)
                .blur(radius: 2)
                .offset(y: 2)

            // リング外輪（シルバーグラデーション）
            Circle()
                .fill(
                    AngularGradient(
                        stops: [
                            .init(color: AppTheme.notebookRingLight,  location: 0.00),
                            .init(color: AppTheme.notebookRingMid,    location: 0.25),
                            .init(color: AppTheme.notebookRingDark,   location: 0.50),
                            .init(color: AppTheme.notebookRingMid,    location: 0.75),
                            .init(color: AppTheme.notebookRingLight,  location: 1.00),
                        ],
                        center: .center
                    )
                )
                .frame(width: outer, height: outer)

            // 内側の穴（スパイン背景を透かす）
            Circle()
                .fill(AppTheme.notebookSpine)
                .frame(width: inner, height: inner)

            // 穴の内側シャドウ（奥行き感）
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.black.opacity(0.20), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: inner, height: inner)

            // 上部ハイライト（光の反射）
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.70), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: outer * 0.65, height: outer * 0.4)
                .offset(y: -outer * 0.18)
                .clipShape(Circle().size(width: outer, height: outer).offset(x: -(outer - outer * 0.65) / 2, y: 0))
        }
        .frame(width: outer, height: outer)
    }

    // MARK: - ヘルパー

    private func ringCount(for height: CGFloat) -> Int {
        max(4, Int(height / 60))
    }

    private func ringSpacing(height: CGFloat, count: Int) -> CGFloat {
        guard count > 1 else { return 0 }
        return (height - 44) / CGFloat(count - 1)
    }
}

#Preview {
    HStack(spacing: 0) {
        NotebookRingView()
            .frame(width: 32)
        AppTheme.notebookPage
            .overlay {
                VStack {
                    Spacer()
                    Text("— 1 —")
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(.gray.opacity(0.4))
                        .padding(.bottom, 14)
                }
            }
    }
    .frame(height: 600)
    .background(AppTheme.backgroundPrimary)
}
