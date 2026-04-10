import SwiftUI

// MARK: - オンボーディングビュー

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)?
    @State private var currentPage = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack {
            // 背景色
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // スキップボタン
                skipButton

                // ページコンテンツ
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        OnboardingPageView(
                            page: page,
                            isActive: currentPage == page.id
                        )
                        .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // 下部コントロール
                bottomControls
            }
        }
    }

    // MARK: - スキップボタン

    private var skipButton: some View {
        HStack {
            Spacer()
            Button {
                completeOnboarding()
            } label: {
                Text("スキップ")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .accessibilityLabel("スキップ")
            .accessibilityHint("オンボーディングをスキップします")
            .padding(.trailing, 24)
            .padding(.top, 8)
        }
    }

    // MARK: - 下部コントロール

    private var bottomControls: some View {
        VStack(spacing: 24) {
            // ページインジケータ
            OnboardingPageIndicator(
                totalPages: pages.count,
                currentPage: currentPage
            )

            // アクションボタン
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation(.spring(duration: 0.4)) {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "次へ" : "はじめる")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.accent, in: Capsule())
                    .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 32)
            .accessibilityLabel(currentPage < pages.count - 1 ? "次へ" : "はじめる")
            .animation(.spring(duration: 0.3), value: currentPage)
        }
        .padding(.bottom, 48)
    }

    // MARK: - オンボーディング完了

    private func completeOnboarding() {
        onComplete?()
        dismiss()
    }
}
