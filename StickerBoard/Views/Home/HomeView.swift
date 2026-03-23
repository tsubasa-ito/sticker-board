import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var stickers: [Sticker]
    @Query private var boards: [Board]

    @State private var showCapture = false
    @State private var animateHeader = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダー
                        headerSection

                        // 統計カード
                        statsRow

                        // メインアクション
                        actionCards

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCapture) {
                NavigationStack {
                    StickerCaptureView()
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateHeader = true
                }
            }
        }
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        VStack(spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("シールボード")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.headerGradient)

                    Text("リアルシールをデジタルコレクション")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                // アプリアイコン風の装飾
                ZStack {
                    Circle()
                        .fill(AppTheme.headerGradient)
                        .frame(width: 48, height: 48)

                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
                .opacity(animateHeader ? 1 : 0)
                .scaleEffect(animateHeader ? 1 : 0.5)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - 統計行

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatBadge(
                icon: "star.fill",
                count: stickers.count,
                label: "シール",
                color: AppTheme.accent
            )

            StatBadge(
                icon: "rectangle.on.rectangle.angled",
                count: boards.count,
                label: "ボード",
                color: AppTheme.secondary
            )
        }
        .opacity(animateHeader ? 1 : 0)
        .offset(y: animateHeader ? 0 : 20)
    }

    // MARK: - アクションカード

    private var actionCards: some View {
        VStack(spacing: 16) {
            // シール追加カード
            Button {
                showCapture = true
            } label: {
                ActionCard(
                    icon: "camera.fill",
                    title: "シールを追加",
                    subtitle: "写真から切り抜いてコレクションに追加",
                    gradient: AppTheme.headerGradient
                )
            }
            .buttonStyle(.plain)

            // ライブラリカード
            NavigationLink {
                StickerLibraryView()
            } label: {
                ActionCard(
                    icon: "square.grid.2x2.fill",
                    title: "シールライブラリ",
                    subtitle: "\(stickers.count)枚のシールをコレクション中",
                    gradient: AppTheme.mintGradient
                )
            }
            .buttonStyle(.plain)

            // ボード一覧カード
            NavigationLink {
                BoardListView()
            } label: {
                ActionCard(
                    icon: "rectangle.on.rectangle.angled",
                    title: "ボード一覧",
                    subtitle: "\(boards.count)枚のボードを作成済み",
                    gradient: LinearGradient(
                        colors: [AppTheme.cream, Color(hex: 0xFFD8A8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .opacity(animateHeader ? 1 : 0)
        .offset(y: animateHeader ? 0 : 30)
    }
}

// MARK: - 統計バッジ

struct StatBadge: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .stickerCard()
    }
}

// MARK: - アクションカード

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: 16) {
            // アイコン
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(gradient)
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }

            // テキスト
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(16)
        .stickerCard()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Sticker.self, Board.self], inMemory: true)
}
