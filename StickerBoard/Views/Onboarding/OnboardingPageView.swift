import SwiftUI

// MARK: - オンボーディングページデータ

struct OnboardingPage: Identifiable {
    let id: Int
    let icon: String
    let secondaryIcon: String?
    let title: LocalizedStringKey
    let description: LocalizedStringKey

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            icon: "camera.fill",
            secondaryIcon: "star.fill",
            title: "シールボードへようこそ！",
            description: "お気に入りのシールを撮影して、\n自分だけのコレクションを作ろう"
        ),
        OnboardingPage(
            id: 1,
            icon: "scissors",
            secondaryIcon: "sparkles",
            title: "シールを撮影するだけ",
            description: "AIが自動で背景を除去。\nキレイに切り抜かれたシールがコレクションに"
        ),
        OnboardingPage(
            id: 2,
            icon: "rectangle.on.rectangle.fill",
            secondaryIcon: "paintbrush.fill",
            title: "自分だけのボードを作ろう",
            description: "シールを自由に配置して、\nフィルターや枠線でデコレーション"
        ),
    ]
}

// MARK: - オンボーディングページビュー

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // イラスト（SF Symbols）
            iconArea
                .opacity(isActive ? 1 : 0)
                .offset(y: isActive ? 0 : 30)
                .animation(.spring(duration: 0.6, bounce: 0.3), value: isActive)

            // テキスト
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 20)
            .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.1), value: isActive)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - アイコンエリア

    private var iconArea: some View {
        ZStack {
            // 外側リング
            Circle()
                .fill(AppTheme.accent.opacity(0.06))
                .frame(width: 164, height: 164)
            // 内側リング
            Circle()
                .fill(AppTheme.accent.opacity(0.12))
                .frame(width: 126, height: 126)
            // メインサークル
            Circle()
                .fill(AppTheme.backgroundCard)
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            // メインアイコン
            Image(systemName: page.icon)
                .font(.system(size: 42))
                .foregroundStyle(AppTheme.accent)

            // セカンダリアイコン（右上バッジ）
            if let secondary = page.secondaryIcon {
                Image(systemName: secondary)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.secondary, in: Circle())
                    .shadow(color: AppTheme.secondary.opacity(0.35), radius: 6, y: 3)
                    .offset(x: 46, y: -46)
            }
        }
        .accessibilityHidden(true)
    }
}
