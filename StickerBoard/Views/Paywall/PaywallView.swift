import SwiftUI
import StoreKit

/// Pro機能のペイウォールシート
struct PaywallView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var isLoadingProducts = false

    private var productsLoaded: Bool {
        subscriptionManager.yearlyProduct != nil
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    featureListSection
                    pricingSection
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }

            // 購入中オーバーレイ
            if isPurchasing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.3)
            }
        }
        .task {
            if !productsLoaded {
                isLoadingProducts = true
                await subscriptionManager.loadProducts()
                isLoadingProducts = false
            }
        }
        .alert("エラー", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        VStack(spacing: 16) {
            // 閉じるボタン
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("あとで")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            // アイコン
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(spacing: 6) {
                Text("StickerBoard Pro")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("すべての機能をアンロック")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - 機能リスト

    private var featureListSection: some View {
        VStack(spacing: 0) {
            featureRow(icon: "star.fill", text: "シール保存", value: "無制限")
            Divider().padding(.horizontal, 16)
            featureRow(icon: "rectangle.on.rectangle.fill", text: "ボード作成", value: "無制限")
            Divider().padding(.horizontal, 16)
            featureRow(icon: "square.dashed", text: "枠線バリエーション", value: "全開放")
            Divider().padding(.horizontal, 16)
            featureRow(icon: "paintpalette.fill", text: "背景パターン", value: "全開放")
            Divider().padding(.horizontal, 16)
            featureRow(icon: "arrow.down.to.line", text: "画像書き出し", value: "ロゴなし")
        }
        .stickerCard()
    }

    private func featureRow(icon: String, text: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - 価格・CTA

    private var pricingSection: some View {
        VStack(spacing: 16) {
            if isLoadingProducts {
                // 商品読み込み中
                ProgressView()
                    .padding(.vertical, 20)
            } else if let yearly = subscriptionManager.yearlyProduct {
                // 年額カード
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(yearly.displayPrice)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("/年")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    if let monthlyPrice = subscriptionManager.yearlyMonthlyPrice {
                        HStack(spacing: 6) {
                            Text("月あたり\(monthlyPrice)")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)

                            let savings = subscriptionManager.savingsPercentage
                            if savings > 0 {
                                Text("\(savings)%おトク")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(AppTheme.accent))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(AppTheme.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.accent, lineWidth: 2)
                }

                // メインCTA
                Button {
                    Task { await purchaseProduct(yearly) }
                } label: {
                    Text("Proではじめる（年額）")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Capsule().fill(AppTheme.accent))
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 12, y: 6)
                }
                .disabled(isPurchasing)

                // 月額サブCTA
                if let monthly = subscriptionManager.monthlyProduct {
                    Button {
                        Task { await purchaseProduct(monthly) }
                    } label: {
                        Text("月額プランで始める \(monthly.displayPrice)/月")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .disabled(isPurchasing)
                }
            } else {
                // 商品読み込み失敗時のリトライ
                VStack(spacing: 12) {
                    Text("プランの読み込みに失敗しました")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)

                    Button {
                        Task {
                            isLoadingProducts = true
                            await subscriptionManager.loadProducts()
                            isLoadingProducts = false
                        }
                    } label: {
                        Text("再試行")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - フッター

    private var footerSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    isPurchasing = true
                    await subscriptionManager.restorePurchases()
                    isPurchasing = false
                    if subscriptionManager.isProUser {
                        dismiss()
                    }
                }
            } label: {
                Text("購入を復元")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .disabled(isPurchasing)

            HStack(spacing: 16) {
                Link("利用規約", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(AppTheme.textTertiary)

                Link("プライバシーポリシー", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    // MARK: - 購入処理

    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        let result = await subscriptionManager.purchase(product)
        isPurchasing = false

        switch result {
        case .success:
            dismiss()
        case .cancelled:
            break
        case .pending:
            errorMessage = "購入処理が保留中です。しばらくお待ちください。"
        case .failed(let error):
            errorMessage = "購入に失敗しました: \(error.localizedDescription)"
        }
    }
}

// MARK: - ProBadge

/// プレミアム機能を示す小さなバッジ（枠線・背景選択UIで使用）
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(AppTheme.accent))
    }
}
