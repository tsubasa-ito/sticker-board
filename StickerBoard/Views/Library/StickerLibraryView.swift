import SwiftUI
import SwiftData

struct StickerLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sticker.createdAt, order: .reverse) private var stickers: [Sticker]
    @State private var stickerToDelete: Sticker?
    @State private var previewSticker: Sticker?
    @Namespace private var previewNamespace

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 14)
    ]

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            Group {
                if stickers.isEmpty {
                    emptyState
                } else {
                    stickerGrid
                }
            }
        }
        .overlay {
            if let sticker = previewSticker {
                StickerPreviewOverlay(
                    sticker: sticker,
                    namespace: previewNamespace
                ) {
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                        previewSticker = nil
                    }
                }
            }
        }
        .navigationTitle("ライブラリ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundPrimary, for: .navigationBar)
        .alert("シールを削除", isPresented: Binding(
            get: { stickerToDelete != nil },
            set: { if !$0 { stickerToDelete = nil } }
        )) {
            Button("削除", role: .destructive) {
                if let sticker = stickerToDelete {
                    deleteSticker(sticker)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このシールをコレクションから削除しますか？")
        }
    }

    // MARK: - 空の状態

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "star.leadinghalf.filled")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.accent.opacity(0.5))
            }

            VStack(spacing: 6) {
                Text("まだシールがありません")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("ホームの「シールを追加」から\n写真を切り抜いてみましょう")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - グリッド

    private var stickerGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // コレクションカウンター
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(AppTheme.accent)
                        .font(.system(size: 12))
                    Text("\(stickers.count)枚のシール")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.horizontal, 4)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(stickers) { sticker in
                        StickerThumbnailView(sticker: sticker)
                            .matchedGeometryEffect(
                                id: sticker.id,
                                in: previewNamespace,
                                isSource: previewSticker?.id != sticker.id
                            )
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                                    previewSticker = sticker
                                }
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("タップしてプレビューを表示")
                            .contextMenu {
                                Button(role: .destructive) {
                                    stickerToDelete = sticker
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(20)
        }
    }

    private func deleteSticker(_ sticker: Sticker) {
        ImageStorage.delete(fileName: sticker.imageFileName)
        modelContext.delete(sticker)
        stickerToDelete = nil
    }
}

// MARK: - プレビューオーバーレイ

struct StickerPreviewOverlay: View {
    let sticker: Sticker
    var namespace: Namespace.ID
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("プレビューを閉じる")

            VStack(spacing: 20) {
                if let image = ImageStorage.load(fileName: sticker.imageFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .matchedGeometryEffect(id: sticker.id, in: namespace)
                        .padding(32)
                        .accessibilityLabel("シールのプレビュー")
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Text(sticker.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .transition(.opacity)
    }
}

struct StickerThumbnailView: View {
    let sticker: Sticker
    @State private var appeared = false

    var body: some View {
        Group {
            if let image = ImageStorage.load(fileName: sticker.imageFileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .frame(width: 100, height: 100)
        .background(AppTheme.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.accent.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .scaleEffect(appeared ? 1 : 0.7)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.3).delay(Double.random(in: 0...0.15))) {
                appeared = true
            }
        }
    }
}
