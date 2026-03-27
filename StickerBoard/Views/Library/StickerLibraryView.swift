import SwiftUI
import SwiftData

struct StickerLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sticker.createdAt, order: .reverse) private var stickers: [Sticker]
    @Query private var boards: [Board]
    @State private var deleteInfo: (sticker: Sticker, boards: [Board])?
    @State private var previewSticker: Sticker?
    @State private var maskEditSticker: Sticker?
    @State private var maskEditOriginalImage: UIImage?
    @State private var maskEditMaskImage: UIImage?
    @State private var maskEditSaved = false
    @State private var showOverwriteError = false
    @State private var showMaskEditLoadError = false
    @State private var thumbnailRefreshID = UUID()
    @Namespace private var previewNamespace
    var onAddSticker: () -> Void = {}

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
                    namespace: previewNamespace,
                    onDismiss: {
                        withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                            previewSticker = nil
                        }
                    },
                    onDelete: {
                        withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                            previewSticker = nil
                        }
                        deleteInfo = (sticker, boardsUsing(sticker))
                    },
                    onMaskEdit: {
                        withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                            previewSticker = nil
                        }
                        startMaskEdit(sticker)
                    }
                )
            }
        }
        .navigationTitle("ライブラリ")
        .navigationBarTitleDisplayMode(.inline)
        .alert("シールを削除", isPresented: Binding(
            get: { deleteInfo != nil },
            set: { if !$0 { deleteInfo = nil } }
        ), presenting: deleteInfo) { info in
            Button("削除", role: .destructive) {
                deleteSticker(info.sticker, from: info.boards)
            }
            Button("キャンセル", role: .cancel) {}
        } message: { info in
            if info.boards.isEmpty {
                Text("このシールをコレクションから削除しますか？")
            } else {
                Text("このシールは\(info.boards.count)個のボードで使用されています。削除するとボードからも取り除かれます。")
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { maskEditOriginalImage != nil && maskEditMaskImage != nil },
            set: { if !$0 { maskEditSticker = nil; maskEditOriginalImage = nil; maskEditMaskImage = nil } }
        ), onDismiss: {
            if maskEditSaved {
                thumbnailRefreshID = UUID()
                maskEditSaved = false
            }
        }) {
            if let originalImage = maskEditOriginalImage,
               let maskImage = maskEditMaskImage {
                MaskEditorView(
                    originalImage: originalImage,
                    maskImage: maskImage
                ) { composited, _ in
                    saveMaskEditResult(composited)
                }
            }
        }
        .alert("保存に失敗しました", isPresented: $showOverwriteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("シールの保存中にエラーが発生しました。もう一度お試しください。")
        }
        .alert("読み込みに失敗しました", isPresented: $showMaskEditLoadError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("シール画像の読み込みに失敗しました。画像が破損している可能性があります。")
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
                    addStickerCard

                    ForEach(stickers) { sticker in
                        StickerThumbnailView(sticker: sticker, refreshTrigger: thumbnailRefreshID)
                            .matchedGeometryEffect(id: sticker.id, in: previewNamespace)
                            .opacity(previewSticker?.id == sticker.id ? 0 : 1)
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                                    previewSticker = sticker
                                }
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("タップしてプレビューを表示")
                            .contextMenu {
                                Button {
                                    startMaskEdit(sticker)
                                } label: {
                                    Label("不要部分を除去", systemImage: "eraser.line.dashed")
                                }
                                Button(role: .destructive) {
                                    deleteInfo = (sticker, boardsUsing(sticker))
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

    private func boardsUsing(_ sticker: Sticker) -> [Board] {
        boards.filter { board in
            board.placements.contains { $0.stickerId == sticker.id }
        }
    }

    private func startMaskEdit(_ sticker: Sticker) {
        guard let image = ImageStorage.load(fileName: sticker.imageFileName),
              let mask = MaskCompositor.generateMaskFromAlpha(image: image) else {
            showMaskEditLoadError = true
            return
        }
        maskEditSticker = sticker
        maskEditOriginalImage = image
        maskEditMaskImage = mask
    }

    private func saveMaskEditResult(_ composited: UIImage) {
        guard let sticker = maskEditSticker else { return }
        do {
            try ImageStorage.overwrite(composited, fileName: sticker.imageFileName)
            maskEditSaved = true
        } catch {
            showOverwriteError = true
        }
    }

    private func deleteSticker(_ sticker: Sticker, from usedBoards: [Board]) {
        for board in usedBoards {
            board.placements = board.placements.filter { $0.stickerId != sticker.id }
            board.updatedAt = Date()
        }
        ImageStorage.delete(fileName: sticker.imageFileName)
        modelContext.delete(sticker)
        deleteInfo = nil
    }

    // MARK: - さらに追加カード

    private var addStickerCard: some View {
        Button(action: onAddSticker) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.12))
                        .frame(width: 38, height: 38)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }

                Text("さらに追加")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(width: 100, height: 100)
            .background(AppTheme.backgroundCard.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(AppTheme.accent.opacity(0.3))
            }
        }
        .accessibilityLabel("シールをさらに追加")
    }
}

// MARK: - プレビューオーバーレイ

struct StickerPreviewOverlay: View {
    let sticker: Sticker
    let namespace: Namespace.ID
    var onDismiss: () -> Void
    var onDelete: () -> Void = {}
    var onMaskEdit: () -> Void = {}

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("プレビューを閉じる")

            VStack(spacing: 20) {
                Spacer(minLength: 0)

                Group {
                    if let image = ImageStorage.load(fileName: sticker.imageFileName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .accessibilityLabel("シールのプレビュー")
                    } else {
                        ProgressView()
                    }
                }
                .matchedGeometryEffect(id: sticker.id, in: namespace)
                .padding(.horizontal, 32)

                Text(sticker.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                // アクションボタン
                HStack(spacing: 16) {
                    Button {
                        onDelete()
                    } label: {
                        Label("削除", systemImage: "trash")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("シールを削除")

                    Button {
                        onMaskEdit()
                    } label: {
                        Label("再編集", systemImage: "eraser.line.dashed")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("マスクを再編集")
                }
                .padding(.top, 4)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 60)
        }
        .transition(.opacity)
    }
}

struct StickerThumbnailView: View {
    let sticker: Sticker
    var refreshTrigger: UUID = UUID()
    @State private var appeared = false
    @State private var thumbnailImage: UIImage?

    var body: some View {
        Group {
            if let image = thumbnailImage {
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
        .task(id: refreshTrigger) {
            thumbnailImage = await Task.detached {
                ImageStorage.loadThumbnail(fileName: sticker.imageFileName, size: 200)
            }.value
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.3).delay(Double.random(in: 0...0.15))) {
                appeared = true
            }
        }
    }
}
