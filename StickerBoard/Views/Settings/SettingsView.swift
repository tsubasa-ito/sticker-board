import SwiftUI
import StoreKit

struct SettingsView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingManageSubscription = false
    @State private var isPurchasing = false
    @State private var isRestoringPurchases = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""
    @State private var selectedPlan: SelectedPlan = .yearly
    @State private var errorMessage: String?

    private enum SelectedPlan {
        case monthly, yearly
    }

    // TODO: #38 で実際のURLに差し替え
    private static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private static let privacyURL = URL(string: "https://www.apple.com/legal/privacy/")!

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    subscriptionSection
                    actionsSection

                    if !subscriptionManager.isProUser {
                        proBenefitsSection
                        faqSection
                    }

                    noticesSection
                    relatedLinksSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .manageSubscriptionsSheet(
            isPresented: $showingManageSubscription,
            subscriptionGroupID: SubscriptionProduct.groupID
        )
        .alert("購入の復元", isPresented: $showRestoreAlert) {
            Button("OK") {}
        } message: {
            Text(restoreAlertMessage)
        }
    }

    // MARK: - サブスクリプションセクション

    private var subscriptionSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "サブスクリプション", icon: "crown")

            VStack(spacing: 0) {
                planRow

                Divider()
                    .padding(.horizontal, 16)

                if subscriptionManager.isProUser {
                    expirationRow

                    Divider()
                        .padding(.horizontal, 16)
                }

                statusRow
            }
            .stickerCard()
        }
    }

    private var planRow: some View {
        HStack {
            Label {
                Text("現在のプラン")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            } icon: {
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(AppTheme.accent)
            }

            Spacer()

            Text(subscriptionManager.currentPlan.displayName)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    subscriptionManager.isProUser
                        ? AppTheme.accent
                        : AppTheme.textSecondary
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var expirationRow: some View {
        HStack {
            Label {
                Text("有効期限")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            } icon: {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.accent)
            }

            Spacer()

            if let date = subscriptionManager.currentSubscriptionExpirationDate {
                Text(date.formatted(.dateTime.locale(Locale(identifier: "ja_JP")).year().month().day()))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var statusRow: some View {
        HStack {
            Label {
                Text("ステータス")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            } icon: {
                Image(systemName: subscriptionManager.isProUser ? "checkmark.seal.fill" : "xmark.seal")
                    .foregroundStyle(subscriptionManager.isProUser ? AppTheme.softOrange : AppTheme.textTertiary)
            }

            Spacer()

            if subscriptionManager.isProUser {
                Text("有効")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.accent, in: Capsule())
            } else {
                Text("未加入")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.textTertiary.opacity(0.12), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - アクションセクション

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isProUser {
                // Proユーザー: プラン管理
                Button {
                    showingManageSubscription = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                        Text("プランを管理")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            } else {
                // 無料ユーザー: プラン選択 + 購入
                planSelectionSection
            }

            restorePurchasesButton
        }
    }

    // MARK: - プラン選択（無料ユーザー向け）

    private var planSelectionSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                // 年額プランカード
                if let yearly = subscriptionManager.yearlyProduct {
                    planCard(
                        product: yearly,
                        label: "年額",
                        isSelected: selectedPlan == .yearly,
                        badge: savingsBadge
                    ) {
                        selectedPlan = .yearly
                    }
                }

                // 月額プランカード
                if let monthly = subscriptionManager.monthlyProduct {
                    planCard(
                        product: monthly,
                        label: "月額",
                        isSelected: selectedPlan == .monthly,
                        badge: nil
                    ) {
                        selectedPlan = .monthly
                    }
                }
            }

            // 購入ボタン
            Button {
                Task { await purchaseSelectedPlan() }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Pro にアップグレード")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isPurchasing)

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func planCard(
        product: Product,
        label: String,
        isSelected: Bool,
        badge: String?,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(AppTheme.accent))
                } else {
                    Text(" ")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .padding(.vertical, 2)
                }

                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)

                Text(product.displayPrice)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)

                if label == "年額", let monthlyPrice = subscriptionManager.yearlyMonthlyPrice {
                    Text("月あたり\(monthlyPrice)")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(AppTheme.textTertiary)
                } else {
                    Text(" ")
                        .font(.system(size: 11, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? AppTheme.accent : AppTheme.borderSubtle,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var savingsBadge: String? {
        let savings = subscriptionManager.savingsPercentage
        return savings > 0 ? "\(savings)%おトク" : nil
    }

    private func purchaseSelectedPlan() async {
        let product: Product?
        switch selectedPlan {
        case .yearly: product = subscriptionManager.yearlyProduct
        case .monthly: product = subscriptionManager.monthlyProduct
        }

        guard let product else { return }

        isPurchasing = true
        errorMessage = nil
        let result = await subscriptionManager.purchase(product)
        isPurchasing = false

        switch result {
        case .success:
            break
        case .cancelled:
            break
        case .pending:
            errorMessage = "購入処理が保留中です。しばらくお待ちください。"
        case .failed(let error):
            errorMessage = "購入に失敗しました: \(error.localizedDescription)"
        }
    }

    private var restorePurchasesButton: some View {
        Button {
            Task {
                isRestoringPurchases = true
                await subscriptionManager.restorePurchases()
                isRestoringPurchases = false
                if subscriptionManager.isProUser {
                    restoreAlertMessage = "Proプランが復元されました"
                } else {
                    restoreAlertMessage = "復元可能な購入が見つかりませんでした"
                }
                showRestoreAlert = true
            }
        } label: {
            HStack {
                if isRestoringPurchases {
                    ProgressView()
                        .tint(AppTheme.accent)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                }

                Text("購入を復元")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isRestoringPurchases)
    }

    // MARK: - Proメリットセクション（無料ユーザー向け）

    private var proBenefitsSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "Pro にアップグレードすると", icon: "crown")

            VStack(spacing: 0) {
                benefitRow(icon: "star.fill", title: "シール保存", value: "無制限")
                benefitRow(icon: "rectangle.on.rectangle.fill", title: "ボード作成", value: "無制限")
                benefitRow(icon: "square.dashed", title: "枠線バリエーション", value: "全開放")
                benefitRow(icon: "paintpalette.fill", title: "背景パターン", value: "全開放")
                benefitRow(icon: "square.and.arrow.down.fill", title: "画像書き出し", value: "ロゴなし")
            }
            .padding(.vertical, 4)
            .stickerCard()
        }
    }

    private func benefitRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - よくある質問セクション（無料ユーザー向け）

    private var faqSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "よくある質問", icon: "questionmark.circle")

            VStack(spacing: 0) {
                faqItem(
                    question: "無料プランでもシールは作れますか？",
                    answer: "はい。無料プランではシール30枚・ボード1枚まで作成できます。"
                )

                Divider().padding(.horizontal, 16)

                faqItem(
                    question: "Proプランはいつでも解約できますか？",
                    answer: "はい。いつでも解約可能です。解約後も有効期限まではPro機能をご利用いただけます。"
                )

                Divider().padding(.horizontal, 16)

                faqItem(
                    question: "機種変更してもProは引き継げますか？",
                    answer: "はい。同じApple IDでサインインし「購入を復元」を行うと引き継げます。"
                )

                Divider().padding(.horizontal, 16)

                faqItem(
                    question: "月額と年額はどちらがお得ですか？",
                    answer: "年額プランは月額換算で約36%おトクです。長期利用の方におすすめします。"
                )
            }
            .stickerCard()
        }
    }

    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Q. \(question)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(answer)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 注意事項セクション

    private var noticesSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "注意事項", icon: "exclamationmark.triangle")

            VStack(alignment: .leading, spacing: 10) {
                noticeItem("有効期限終了の24時間前までに解約されない限り、自動的に継続購入となります。")
                noticeItem("ご利用料金はApp Storeアカウントに対して請求されます。")
                noticeItem("アプリを削除するだけでは継続購入は解除されません。ご注意ください。")
                noticeItem("異なるアカウントで重複課金した場合の返金対応はできかねますのでご了承ください。")
            }
            .padding(16)
            .stickerCard()
        }
    }

    private func noticeItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("・")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textTertiary)

            Text(text)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    // MARK: - 関連リンクセクション

    private var relatedLinksSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "関連リンク", icon: "link")

            VStack(spacing: 0) {
                linkRow(title: "利用規約", url: Self.termsURL)

                Divider().padding(.horizontal, 16)

                linkRow(title: "プライバシーポリシー", url: Self.privacyURL)
            }
            .stickerCard()
        }
    }

    private func linkRow(title: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                Text(title)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - ヘルパー

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
