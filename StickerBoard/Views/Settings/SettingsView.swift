import SwiftUI
import StoreKit

struct SettingsView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    @State private var showingManageSubscription = false
    @State private var isRestoringPurchases = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    subscriptionSection

                    if !subscriptionManager.isProUser {
                        proBenefitsSection
                    }

                    actionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
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
                // 現在のプラン
                planRow

                Divider()
                    .padding(.horizontal, 16)

                // 有効期限（Proユーザーのみ）
                if subscriptionManager.isProUser {
                    expirationRow

                    Divider()
                        .padding(.horizontal, 16)
                }

                // ステータス
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

    // MARK: - アクションセクション

    private var actionsSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "アクション", icon: "gearshape")

            VStack(spacing: 12) {
                // プラン変更ボタン
                changePlanButton

                // 購入を復元ボタン
                restorePurchasesButton
            }
        }
    }

    private var changePlanButton: some View {
        Button {
            if subscriptionManager.isProUser {
                showingManageSubscription = true
            } else {
                showingPaywall = true
            }
        } label: {
            HStack {
                Image(systemName: subscriptionManager.isProUser ? "arrow.triangle.2.circlepath" : "crown.fill")
                    .font(.system(size: 16, weight: .semibold))

                Text(subscriptionManager.isProUser ? "プランを管理" : "Pro にアップグレード")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
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
