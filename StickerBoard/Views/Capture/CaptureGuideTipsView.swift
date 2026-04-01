import SwiftUI

struct CaptureGuideTipsView: View {
    @AppStorage("captureGuideCollapsed") private var isCollapsed = false

    private let tips: [(icon: String, text: String)] = [
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
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.cream)
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
            .accessibilityValue(isCollapsed ? "閉じている" : "開いている")

            // ヒント一覧
            if !isCollapsed {
                VStack(spacing: 8) {
                    ForEach(tips, id: \.text) { tip in
                        HStack(spacing: 10) {
                            Image(systemName: tip.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.secondary)
                                .frame(width: 20)
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
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cream.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.cream.opacity(0.4), lineWidth: 1)
        )
    }
}
