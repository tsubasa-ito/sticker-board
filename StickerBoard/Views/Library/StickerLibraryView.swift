import os
import SwiftUI
import SwiftData

struct StickerLibraryView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.tebasaki.StickerBoard",
        category: "StickerLibraryView"
    )
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var boards: [Board]
    @State private var displayedStickers: [Sticker] = []
    @State private var totalCount: Int = 0
    @State private var hasMorePages = true
    @State private var deleteInfo: (sticker: Sticker, boards: [Board])?
    @State private var previewSticker: Sticker?
    @State private var maskEditSticker: Sticker?
    @State private var maskEditOriginalImage: UIImage?
    @State private var maskEditMaskImage: UIImage?
    @State private var maskEditSaved = false
    @State private var showOverwriteError = false
    @State private var showDeleteError = false
    @State private var showMaskEditLoadError = false
    @State private var thumbnailRefreshID = UUID()
    @State private var showRotateError = false
    @State private var sortNewest = true
    @State private var showSaveToPhotosResult = false
    @State private var saveToPhotosSuccess = false
    @Namespace private var previewNamespace
    let refreshTrigger: UUID
    var onAddSticker: () -> Void = {}
    /// ピッカーモード: nil 以外のとき、シールタップでコールバックを呼び出してピッカーとして動作する
    var onStickerPicked: ((Sticker) -> Void)? = nil
    /// 通知ディープリンク経由で開いた際にプレビュー表示するシールID（消費後に nil リセットされる）
    var highlightStickerId: Binding<UUID?> = .constant(nil)

    private var isPicking: Bool { onStickerPicked != nil }

    private let pageSize = 30

    private var sortBinding: Binding<Bool> {
        Binding(get: { sortNewest }, set: { newVal in
            sortNewest = newVal
            resetAndReload()
        })
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(get: { deleteInfo != nil }, set: { if !$0 { deleteInfo = nil } })
    }

    private var maskEditBinding: Binding<Bool> {
        Binding(
            get: { maskEditOriginalImage != nil && maskEditMaskImage != nil },
            set: { if !$0 { maskEditSticker = nil; maskEditOriginalImage = nil; maskEditMaskImage = nil } }
        )
    }

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 14)
    ]

    var body: some View {
        libraryContent
            .alert("回転に失敗しました", isPresented: $showRotateError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("シールの回転中にエラーが発生しました。もう一度お試しください。")
            }
            .alert("保存に失敗しました", isPresented: $showOverwriteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("シールの保存中にエラーが発生しました。もう一度お試しください。")
            }
            .alert("削除に失敗しました", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("シール画像の削除中にエラーが発生しました。もう一度お試しください。")
            }
            .alert("読み込みに失敗しました", isPresented: $showMaskEditLoadError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("シール画像の読み込みに失敗しました。画像が破損している可能性があります。")
            }
            .alert(
                saveToPhotosSuccess ? LocalizedStringKey("写真を保存しました") : LocalizedStringKey("保存に失敗しました"),
                isPresented: $showSaveToPhotosResult
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                if !saveToPhotosSuccess {
                    Text("フォトライブラリへの保存中にエラーが発生しました。アクセス許可を確認してください。")
                }
            }
    }

    private var libraryContent: some View {
        mainStack
            .overlay {
                if !isPicking, let sticker = previewSticker {
                    StickerPreviewOverlay(
                        sticker: sticker,
                        namespace: previewNamespace,
                        refreshTrigger: thumbnailRefreshID,
                        onDismiss: {
                            withAnimation(.spring(duration: 0.35, bounce: 0.2)) { previewSticker = nil }
                        },
                        onDelete: {
                            withAnimation(.spring(duration: 0.35, bounce: 0.2)) { previewSticker = nil }
                            deleteInfo = (sticker, boardsUsing(sticker))
                        },
                        onMaskEdit: {
                            withAnimation(.spring(duration: 0.35, bounce: 0.2)) { previewSticker = nil }
                            startMaskEdit(sticker)
                        },
                        onRotate: { clockwise in rotateSticker(sticker, clockwise: clockwise) },
                        onShare: { StickerShareService.share(sticker) },
                        onSaveToPhotos: { saveSticker(sticker) }
                    )
                }
            }
            .navigationTitle(isPicking ? "シールを選択" : "ライブラリ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isPicking {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") { dismiss() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("並び替え", selection: sortBinding) {
                            Text("新着順").tag(true)
                            Text("古い順").tag(false)
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(sortNewest ? AppTheme.textSecondary : AppTheme.accent)
                    }
                    .accessibilityLabel("並び替え")
                }
            }
            .alert("シールを削除", isPresented: deleteAlertBinding, presenting: deleteInfo) { info in
                Button("削除", role: .destructive) { deleteSticker(info.sticker, from: info.boards) }
                Button("キャンセル", role: .cancel) {}
            } message: { info in
                if info.boards.isEmpty {
                    Text("このシールをコレクションから削除しますか？")
                } else {
                    Text("このシールは\(info.boards.count)個のボードで使用されています。削除するとボードからも取り除かれます。")
                }
            }
            .fullScreenCover(isPresented: maskEditBinding, onDismiss: {
                if maskEditSaved {
                    thumbnailRefreshID = UUID()
                    maskEditSaved = false
                }
            }) {
                if let originalImage = maskEditOriginalImage,
                   let maskImage = maskEditMaskImage {
                    MaskEditorView(originalImage: originalImage, maskImage: maskImage) { composited, _ in
                        saveMaskEditResult(composited)
                    }
                }
            }
    }

    private var mainStack: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            Group {
                if totalCount == 0 {
                    emptyState
                } else {
                    stickerGrid
                }
            }
        }
        .onAppear {
            if displayedStickers.isEmpty {
                resetAndReload()
            } else {
                refreshIfNeeded()
            }
        }
        .onChange(of: refreshTrigger) {
            refreshIfNeeded()
        }
        .task(id: highlightStickerId.wrappedValue) {
            guard let targetId = highlightStickerId.wrappedValue else { return }
            if let sticker = displayedStickers.first(where: { $0.id == targetId }) {
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) { previewSticker = sticker }
            } else {
                var descriptor = FetchDescriptor<Sticker>(
                    predicate: #Predicate { $0.id == targetId }
                )
                descriptor.fetchLimit = 1
                if let sticker = try? modelContext.fetch(descriptor).first {
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) { previewSticker = sticker }
                }
            }
            highlightStickerId.wrappedValue = nil
        }
    }

    // MARK: - 空の状態

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.06))
                    .frame(width: 116, height: 116)
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 92, height: 92)
                Image(systemName: "star.leadinghalf.filled")
                    .font(.system(size: 42))
                    .foregroundStyle(AppTheme.accent.opacity(0.6))
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("まだシールがありません")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("写真を切り抜いて\nオリジナルシールを作ろう")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddSticker) {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                    Text("シールを追加する")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppTheme.accent, in: Capsule())
                .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, y: 4)
            }
            .accessibilityLabel("シールを追加する")
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
                        .font(.system(size: 11))
                        .accessibilityHidden(true)
                    Text("\(totalCount)枚")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.accent.opacity(0.1), in: Capsule())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("全\(totalCount)枚のシール")

                LazyVGrid(columns: columns, spacing: 14) {
                    if !isPicking {
                        addStickerCard
                    }

                    ForEach(displayedStickers) { sticker in
                        stickerCell(for: sticker)
                    }
                }

                if hasMorePages && !displayedStickers.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(AppTheme.accent)
                            .accessibilityLabel("さらに読み込み中")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(20)
        }
        .safeAreaPadding(.bottom, 80)
    }

    // MARK: - シールセル（ピッカーモード対応）

    /// ピッカーモード（isPicking == true）では contextMenu を付与せず、ロングプレスのプレビュー動作を防ぐ
    @ViewBuilder
    private func stickerCell(for sticker: Sticker) -> some View {
        let base = Button {
            if isPicking {
                onStickerPicked?(sticker)
            } else {
                withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                    previewSticker = sticker
                }
            }
        } label: {
            StickerThumbnailView(sticker: sticker, refreshTrigger: thumbnailRefreshID)
                .matchedGeometryEffect(id: sticker.id, in: previewNamespace)
                .opacity(previewSticker?.id == sticker.id ? 0 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityHint(isPicking ? String(localized: "タップしてボードに追加") : String(localized: "タップしてプレビューを表示"))
        .onAppear {
            if sticker.id == displayedStickers.last?.id {
                loadNextPage()
            }
        }

        if isPicking {
            base
        } else {
            base
                .contextMenu {
                    Button {
                        StickerShareService.share(sticker)
                    } label: {
                        Label("共有", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        saveSticker(sticker)
                    } label: {
                        Label("写真に保存", systemImage: "square.and.arrow.down")
                    }
                    Divider()
                    Button {
                        rotateSticker(sticker, clockwise: false)
                    } label: {
                        Label("左に回転", systemImage: "rotate.left")
                    }
                    Button {
                        rotateSticker(sticker, clockwise: true)
                    } label: {
                        Label("右に回転", systemImage: "rotate.right")
                    }
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

    private func boardsUsing(_ sticker: Sticker) -> [Board] {
        boards.filter { board in
            board.placements.contains { $0.stickerId == sticker.id }
        }
    }

    private func rotateSticker(_ sticker: Sticker, clockwise: Bool) {
        Task {
            do {
                let fileName = sticker.imageFileName
                try await Task.detached {
                    try ImageStorage.rotateAndOverwrite(fileName: fileName, clockwise: clockwise)
                }.value
                thumbnailRefreshID = UUID()
                AccessibilityNotification.Announcement(clockwise ? "右に回転しました" : "左に回転しました").post()
            } catch {
                showRotateError = true
            }
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

    private func saveSticker(_ sticker: Sticker) {
        Task {
            let success = await StickerShareService.saveToPhotos(sticker)
            saveToPhotosSuccess = success
            showSaveToPhotosResult = true
        }
    }

    private func deleteSticker(_ sticker: Sticker, from usedBoards: [Board]) {
        do {
            try ImageStorage.delete(fileName: sticker.imageFileName)
        } catch {
            showDeleteError = true
            return
        }
        for board in usedBoards {
            board.placements = board.placements.filter { $0.stickerId != sticker.id }
            board.updatedAt = Date()
        }
        modelContext.delete(sticker)
        displayedStickers.removeAll { $0.id == sticker.id }
        totalCount = max(totalCount - 1, 0)
        deleteInfo = nil
    }

    // MARK: - ページネーション

    private func resetAndReload() {
        displayedStickers = []
        hasMorePages = true
        fetchTotalCount()
        loadNextPage()
    }

    private func refreshIfNeeded() {
        do {
            let currentCount = try modelContext.fetchCount(FetchDescriptor<Sticker>())
            if currentCount != totalCount {
                resetAndReload()
            }
        } catch {
            Self.logger.error("Error checking sticker count: \(error)")
        }
    }

    private func fetchTotalCount() {
        do {
            totalCount = try modelContext.fetchCount(FetchDescriptor<Sticker>())
        } catch {
            Self.logger.error("Error fetching total sticker count: \(error)")
            totalCount = 0
        }
    }

    private func loadNextPage() {
        guard hasMorePages else { return }
        var descriptor = FetchDescriptor<Sticker>(
            sortBy: [SortDescriptor(\Sticker.createdAt, order: sortNewest ? .reverse : .forward)]
        )
        descriptor.fetchOffset = displayedStickers.count
        descriptor.fetchLimit = pageSize
        do {
            let page = try modelContext.fetch(descriptor)
            displayedStickers.append(contentsOf: page)
            hasMorePages = page.count == pageSize
        } catch {
            Self.logger.error("Error fetching next page of stickers: \(error)")
            hasMorePages = false
        }
    }

    // MARK: - さらに追加カード

    private var addStickerCard: some View {
        Button(action: onAddSticker) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }

                Text("さらに追加")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 100, height: 100)
            .background(AppTheme.accent.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(AppTheme.accent.opacity(0.4))
            }
        }
        .accessibilityLabel("シールをさらに追加")
    }
}

// MARK: - プレビューオーバーレイ

struct StickerPreviewOverlay: View {
    let sticker: Sticker
    let namespace: Namespace.ID
    var refreshTrigger: UUID = UUID()
    var onDismiss: () -> Void
    var onDelete: () -> Void = {}
    var onMaskEdit: () -> Void = {}
    var onRotate: (Bool) -> Void = { _ in }
    var onShare: () -> Void = {}
    var onSaveToPhotos: () -> Void = {}

    @State private var previewImage: UIImage?

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
                    if let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .holographicSticker(
                                image: image,
                                intensity: 0.8,
                                maxRotation: 15,
                                perspective: 0.4,
                                dynamicShadow: true,
                                parallaxOffset: 20
                            )
                            .accessibilityLabel("シールのプレビュー")
                    } else {
                        ProgressView()
                    }
                }
                .matchedGeometryEffect(id: sticker.id, in: namespace)
                .padding(.horizontal, 32)
                .task(id: refreshTrigger) {
                    previewImage = await Task.detached {
                        ImageStorage.load(fileName: sticker.imageFileName)
                    }.value
                }

                Text(sticker.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer(minLength: 0)

                // 統合アクションバー（タブバーとホームインジケーター分の余白を確保）
                stickerActionBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, actionBarBottomPadding)
            }
            .padding(.top, 60)
        }
        .transition(.opacity)
    }

    /// タブバー（49pt）＋ホームインジケーター領域を考慮したアクションバーの底部余白
    private var actionBarBottomPadding: CGFloat {
        let homeIndicatorBottom = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.bottom ?? 34
        return homeIndicatorBottom + 49 + 16  // ホームインジケーター + タブバー + 余白
    }

    // MARK: - 統合アクションバー

    private var stickerActionBar: some View {
        HStack(spacing: 0) {
            // グループ1: 回転
            HStack(spacing: 0) {
                overlayActionButton(
                    icon: "rotate.left",
                    label: String(localized: "左回転"),
                    accessLabel: "左に90度回転",
                    accessHint: "シールを反時計回りに90度回転します"
                ) { onRotate(false) }

                overlayActionButton(
                    icon: "rotate.right",
                    label: String(localized: "右回転"),
                    accessLabel: "右に90度回転",
                    accessHint: "シールを時計回りに90度回転します"
                ) { onRotate(true) }
            }
            .frame(maxWidth: .infinity)

            actionBarDivider

            // グループ2: 出力
            HStack(spacing: 0) {
                overlayActionButton(
                    icon: "square.and.arrow.up",
                    label: String(localized: "共有"),
                    accessLabel: "シールを共有",
                    accessHint: "シール画像をAirDrop・SNS等で共有します"
                ) { onShare() }

                overlayActionButton(
                    icon: "square.and.arrow.down",
                    label: String(localized: "写真に保存"),
                    accessLabel: "写真に保存",
                    accessHint: "シール画像をフォトライブラリに保存します"
                ) { onSaveToPhotos() }
            }
            .frame(maxWidth: .infinity)

            actionBarDivider

            // グループ3: 編集・削除
            HStack(spacing: 0) {
                overlayActionButton(
                    icon: "eraser.line.dashed",
                    label: String(localized: "再編集"),
                    accessLabel: "マスクを再編集"
                ) { onMaskEdit() }

                overlayActionButton(
                    icon: "trash",
                    label: String(localized: "削除"),
                    accessLabel: "シールを削除",
                    tint: Color(red: 1.0, green: 0.35, blue: 0.35)
                ) { onDelete() }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var actionBarDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.18))
            .frame(width: 1, height: 36)
    }

    @ViewBuilder
    private func overlayActionButton(
        icon: String,
        label: String,
        accessLabel: String,
        accessHint: String = "",
        tint: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(tint)
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(tint.opacity(0.75))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessLabel)
        .accessibilityHint(accessHint)
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
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 100, height: 100)
        .background(AppTheme.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AppTheme.accent.opacity(0.08), lineWidth: 1)
        }
        .holographicCard()
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
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
