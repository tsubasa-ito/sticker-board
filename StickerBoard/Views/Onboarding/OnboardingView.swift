import SwiftUI

// MARK: - オンボーディングビュー

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
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
                .animation(.spring(duration: 0.4), value: currentPage)

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
                    .frame(width: 200, height: 52)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .animation(.spring(duration: 0.3), value: currentPage)
        }
        .padding(.bottom, 48)
    }

    // MARK: - オンボーディング完了

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}
