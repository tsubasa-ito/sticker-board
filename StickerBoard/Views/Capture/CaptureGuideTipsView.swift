import SwiftUI

struct CaptureGuideTipsView: View {
    @AppStorage("captureGuideCollapsed") private var isCollapsed = false

    private let tips: [(icon: String, text: LocalizedStringKey)] = [
        ("arrow.up.left.and.arrow.down.right", "シールをできるだけ大きく写す"),
        ("rectangle.dashed", "背景はなるべく無地・シンプルに"),
        ("sun.max.fill", "明るい場所で撮影する"),
        ("shadow", "シールに影がかからないように"),
        ("plus.viewfinder", "シールを写真の中央に"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー（タップで折りたたみ）
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    isCollapsed.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                        .accessibilityHidden(true)

                    Text("きれいに切り抜くコツ")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("きれいに切り抜くコツ")
            .accessibilityValue(isCollapsed ? Text("閉じている") : Text("開いている"))

            // ヒント一覧
            if !isCollapsed {
                VStack(spacing: 10) {
                    ForEach(tips, id: \.icon) { tip in
                        HStack(spacing: 10) {
                            Image(systemName: tip.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.secondary)
                                .frame(width: 28, height: 28)
                                .background(AppTheme.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                                .accessibilityHidden(true)

                            Text(tip.text)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)

                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .stickerCard()
    }
}
