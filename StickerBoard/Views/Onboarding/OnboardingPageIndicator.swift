import SwiftUI

// MARK: - カスタムページインジケータ

struct OnboardingPageIndicator: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? AppTheme.accent : AppTheme.borderSubtle)
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: currentPage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ページインジケーター")
        .accessibilityValue("ページ \(currentPage + 1) / \(totalPages)")
    }
}
