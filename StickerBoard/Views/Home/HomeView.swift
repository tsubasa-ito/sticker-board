import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayScale) private var displayScale

    /// 表示対象の手帳
    var notebook: Notebook

    @Query private var boards: [Board]

    private let newPageTag = "new-page"

    @Binding var hideTabBar: Bool
    @Binding var deepLinkBoardId: UUID?
    var onBoardCreated: () -> Void = {}

    @State private var showingBoardTypePicker = false
    @State private var currentPageTag: String? = "cover"
    /// 表紙エディタ用（通常ページの selectedBoard と分離してクラッシュを防ぐ）
    @State private var selectedCoverBoard: Board?

    init(notebook: Notebook, hideTabBar: Binding<Bool>, deepLinkBoardId: Binding<UUID?>, onBoardCreated: @escaping () -> Void = {}) {
        self.notebook = notebook
        self._hideTabBar = hideTabBar
        self._deepLinkBoardId = deepLinkBoardId
        self.onBoardCreated = onBoardCreated
        let notebookId = notebook.id.uuidString
        self._boards = Query(
            filter: #Predicate<Board> { board in board.notebookIdString == notebookId },
            sort: \Board.createdAt,
            order: .forward
        )
    }
    @State private var animateIn = false
    @State private var selectedBoard: Board?
    @State private var boardToRename: Board?
    @State private var showingRenameBoard = false
    @State private var renameBoardTitle = ""
    @State private var boardToDelete: Board?
    @State private var showingDeleteConfirmation = false
    @State private var showingOnboarding = false
    @State private var showingPaywall = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                notebookPagesView
                    .frame(maxHeight: .infinity)

                notebookPageDots
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                Spacer(minLength: 90)
            }
        }
        .navigationTitle(currentPageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityLabel("設定")
                .accessibilityHint("設定画面を開きます")
            }
            ToolbarItem(placement: .principal) {
                Text(currentPageTitle)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingOnboarding = true } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityLabel("ヘルプ")
                .accessibilityHint("使い方ガイドを表示します")
            }
        }
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView()
                .onAppear { hideTabBar = true }
                .onDisappear { hideTabBar = false }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        // 表紙専用ナビゲーション（pageIndex=0 でリングなし）
        .navigationDestination(item: $selectedCoverBoard) { board in
            BoardEditorView(board: board, pageIndex: 0)
                .onAppear { hideTabBar = true }
                .onDisappear { hideTabBar = false }
        }
        // 通常ページナビゲーション
        .navigationDestination(item: $selectedBoard) { board in
            let pageIndex = (regularBoards.firstIndex(where: { $0.id == board.id }) ?? 0) + 1
            BoardEditorView(board: board, pageIndex: pageIndex)
                .onAppear { hideTabBar = true }
                .onDisappear { hideTabBar = false }
        }
        .sheet(isPresented: $showingBoardTypePicker) {
            NewBoardSheet { title, boardType in
                createBoard(title: title, boardType: boardType)
            }
        }
        .alert("ボード名を変更", isPresented: $showingRenameBoard) {
            TextField("新しいボード名", text: $renameBoardTitle)
            Button("変更") { renameBoard() }
            Button("キャンセル", role: .cancel) {
                boardToRename = nil
                renameBoardTitle = ""
            }
        } message: {
            Text("新しいボードの名前を入力してください")
        }
        .alert("削除の確認", isPresented: $showingDeleteConfirmation, presenting: boardToDelete) { board in
            Button("削除", role: .destructive) { deleteBoard(board) }
            Button("キャンセル", role: .cancel) { boardToDelete = nil }
        } message: { board in
            Text("「\(board.title)」を削除しますか？\nこの操作は取り消せません。")
        }
        .task {
            // 表紙ボードが存在しない場合は自動作成
            if coverBoard == nil {
                let cover = Board(title: "表紙")
                cover.notebookIdString = notebook.id.uuidString
                modelContext.insert(cover)
                try? modelContext.save()
                notebook.coverBoardId = cover.id.uuidString
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { animateIn = true }
        }
        .onChange(of: deepLinkBoardId) {
            guard let boardId = deepLinkBoardId else { return }
            if let board = boards.first(where: { $0.id == boardId }) {
                selectedBoard = board
            }
            deepLinkBoardId = nil
        }
    }

    // MARK: - 表紙・通常ページの分離

    /// 表紙として指定されたボード
    private var coverBoard: Board? {
        boards.first { $0.id.uuidString == notebook.coverBoardId }
    }

    /// 表紙を除いた通常ページ一覧
    private var regularBoards: [Board] {
        boards.filter { $0.id.uuidString != notebook.coverBoardId }
    }

    // MARK: - 手帳ページ群（ScrollView + ページめくりアニメーション）

    private var notebookPagesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {

                // 表紙（フェード＋スケール）
                coverPage
                    .containerRelativeFrame(.horizontal)
                    .id("cover")
                    .scrollTransition(axis: .horizontal) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1.0 : max(0.45, 1.0 - abs(phase.value) * 0.55))
                            .scaleEffect(phase.isIdentity ? 1.0 : max(0.96, 1.0 - abs(phase.value) * 0.04))
                    }

                // ボードページ（リング軸中心の3Dフリップ）
                ForEach(Array(regularBoards.enumerated()), id: \.element.id) { index, board in
                    let pageIndex = index + 1
                    let ringOnLeft = pageIndex % 2 == 1

                    boardPage(board: board, pageIndex: pageIndex)
                        .containerRelativeFrame(.horizontal)
                        .id(board.id.uuidString)
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                // リング側を軸にページが"開かれる"回転
                                .rotation3DEffect(
                                    .degrees(Double(ringOnLeft ? 1 : -1) * phase.value * 12),
                                    axis: (x: 0, y: 1, z: 0),
                                    anchor: ringOnLeft ? .leading : .trailing,
                                    perspective: 0.28
                                )
                                .opacity(phase.isIdentity ? 1.0 : max(0.45, 1.0 - abs(phase.value) * 0.50))
                        }
                }

                // 新規ページ枠（最終ページに合わせた方向）
                let newPageIndex = regularBoards.count + 1
                let newRingOnLeft = newPageIndex % 2 == 1
                newPagePlaceholder
                    .containerRelativeFrame(.horizontal)
                    .id(newPageTag)
                    .scrollTransition(axis: .horizontal) { content, phase in
                        content
                            .rotation3DEffect(
                                .degrees(Double(newRingOnLeft ? 1 : -1) * phase.value * 12),
                                axis: (x: 0, y: 1, z: 0),
                                anchor: newRingOnLeft ? .leading : .trailing,
                                perspective: 0.28
                            )
                            .opacity(phase.isIdentity ? 1.0 : max(0.45, 1.0 - abs(phase.value) * 0.50))
                    }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $currentPageTag)
        .scrollIndicators(.hidden)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 24)
    }

    // MARK: - 表紙ページ（ページ0・リングなし・デコレーション可）

    private var coverPage: some View {
        ZStack {
            if let cover = coverBoard {
                // 実際のボードコンテンツ（背景＋シール）
                BoardCardBackground(config: cover.backgroundPattern)
                if !cover.placements.isEmpty {
                    boardStickerPreview(cover.placements, boardType: cover.boardType)
                } else {
                    // 未デコレーション時のデフォルト表示
                    defaultCoverDecoration
                }
            } else {
                AppTheme.notebookCover
                defaultCoverDecoration
            }

            // 外枠（透明プラスチック感）
            Rectangle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.7), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            // 下部タイトルバッジ
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("シールボード")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary.opacity(0.85))
                        Text(regularBoards.isEmpty
                             ? "右にスワイプしてページを追加"
                             : (regularBoards.count == 1 ? "1ページ" : "\(regularBoards.count)ページ"))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.leading, 16)
                    .padding(.bottom, 20)
                    Spacer()
                }
            }
            .allowsHitTesting(false)
        }
        .padding(.vertical, 8)
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 6)
        .contentShape(Rectangle())
        .onTapGesture {
            // 専用 State を使うことで通常ページの navigationDestination と衝突しない
            if let cover = coverBoard { selectedCoverBoard = cover }
        }
        .accessibilityLabel("表紙。タップして編集します")
        .accessibilityHint("シールや背景を追加してデコレーションできます")
        .accessibilityAddTraits(.isButton)
    }

    private var defaultCoverDecoration: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.10))
                    .frame(width: 90, height: 90)
                Circle()
                    .strokeBorder(AppTheme.accent.opacity(0.18), lineWidth: 1.5)
                    .frame(width: 90, height: 90)
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(AppTheme.accent.opacity(0.7))
            }
            Text("タップして表紙をデコレーション")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textTertiary.opacity(0.6))
        }
        .accessibilityHidden(true)
    }

    // MARK: - ボードページ（奇数=リング左、偶数=リング右）

    private func boardPage(board: Board, pageIndex: Int) -> some View {
        let ringOnLeft = pageIndex % 2 == 1

        return HStack(spacing: 0) {
            if ringOnLeft {
                NotebookRingView().frame(width: 32)
            }

            ZStack {
                // クリアページスリーブ感のある白いページ
                AppTheme.notebookPage
                    .overlay {
                        // ページ外枠（プラスチックスリーブの縁取り）
                        Rectangle()
                            .strokeBorder(AppTheme.notebookSpine.opacity(0.4), lineWidth: 1)
                    }

                boardPreviewContent(board: board)
                pageNumberLabel(pageIndex: pageIndex, ringOnLeft: ringOnLeft)
            }
            // めくれる側のエッジシャドウ（ページの厚み感）
            .shadow(
                color: .black.opacity(0.06),
                radius: 6,
                x: ringOnLeft ? 3 : -3,
                y: 0
            )

            if !ringOnLeft {
                NotebookRingView().frame(width: 32)
            }
        }
        .padding(.vertical, 8)
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 5)
        .contentShape(Rectangle())
        .onTapGesture { selectedBoard = board }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(board.title)、シール\(board.placements.count)枚")
        .accessibilityHint("タップしてページを編集します")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - 新規ページプレースホルダー

    private var newPagePlaceholder: some View {
        let pageIndex = boards.count + 1
        let ringOnLeft = pageIndex % 2 == 1

        return HStack(spacing: 0) {
            if ringOnLeft {
                NotebookRingView().frame(width: 32)
            }

            ZStack {
                AppTheme.notebookPage
                    .overlay {
                        Rectangle()
                            .strokeBorder(AppTheme.notebookSpine.opacity(0.4), lineWidth: 1)
                    }

                Rectangle()
                    .strokeBorder(
                        AppTheme.accent.opacity(0.18),
                        style: StrokeStyle(lineWidth: 1.5, dash: [14, 10])
                    )
                    .padding(32)

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.08))
                            .frame(width: 76, height: 76)
                        Circle()
                            .strokeBorder(
                                AppTheme.accent.opacity(0.22),
                                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                            )
                            .frame(width: 76, height: 76)
                        Image(systemName: "plus")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(AppTheme.accent)
                    }

                    VStack(spacing: 6) {
                        Text("新しいページを追加")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("タップしてページを作成")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                pageNumberLabel(pageIndex: pageIndex, ringOnLeft: ringOnLeft)
            }
            .shadow(
                color: .black.opacity(0.04),
                radius: 8,
                x: ringOnLeft ? 4 : -4,
                y: 0
            )

            if !ringOnLeft {
                NotebookRingView().frame(width: 32)
            }
        }
        .padding(.vertical, 8)
        .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: 5)
        .contentShape(Rectangle())
        .onTapGesture {
            if !SubscriptionManager.shared.isProUser && regularBoards.count >= 1 {
                showingPaywall = true
            } else {
                showingBoardTypePicker = true
            }
        }
        .accessibilityLabel("新しいページを追加")
        .accessibilityHint("タップして新しいページを作成します")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - ボードプレビューコンテンツ

    private func boardPreviewContent(board: Board) -> some View {
        ZStack {
            BoardCardBackground(config: board.backgroundPattern)

            if board.placements.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textTertiary.opacity(0.25))
                        .accessibilityHidden(true)
                    Text("シールを貼ってみよう")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textTertiary.opacity(0.35))
                }
            } else {
                boardStickerPreview(board.placements, boardType: board.boardType)
            }

            boardTitleOverlay(board: board)
        }
    }

    private func boardTitleOverlay(board: Board) -> some View {
        VStack {
            HStack(alignment: .top) {
                Text(board.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.80))
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 14)
                    .padding(.leading, 12)

                Spacer()

                Menu {
                    Button {
                        boardToRename = board
                        renameBoardTitle = board.title
                        showingRenameBoard = true
                    } label: {
                        Label("名前を変更", systemImage: "pencil")
                    }
                    Button { shareBoardAsImage(board) } label: {
                        Label("共有", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(role: .destructive) {
                        boardToDelete = board
                        showingDeleteConfirmation = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                        .padding(9)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                }
                .accessibilityLabel("メニュー")
                .accessibilityHint("ページの名前変更や削除ができます")
            }
            Spacer()
        }
    }

    // MARK: - ページ番号ラベル

    private func pageNumberLabel(pageIndex: Int, ringOnLeft: Bool) -> some View {
        VStack {
            Spacer()
            HStack {
                if ringOnLeft { Spacer() }
                Text("— \(pageIndex) —")
                    .font(.system(size: 11, weight: .light, design: .serif))
                    .foregroundStyle(AppTheme.textTertiary.opacity(0.45))
                    .padding(ringOnLeft ? .trailing : .leading, 16)
                    .padding(.bottom, 14)
                if !ringOnLeft { Spacer() }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - ページドットインジケーター

    private var notebookPageDots: some View {
        let totalPages = regularBoards.count + 2  // 表紙 + 通常ページ + 新規枠
        return HStack(spacing: 5) {
            ForEach(0..<totalPages, id: \.self) { index in
                let isCurrent = index == notebookCurrentIndex
                Capsule()
                    .fill(isCurrent ? AppTheme.accent : AppTheme.accent.opacity(0.2))
                    .frame(width: isCurrent ? 20 : 6, height: 6)
                    .animation(.spring(duration: 0.3), value: notebookCurrentIndex)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ページ \(notebookCurrentIndex + 1) / \(totalPages)")
    }

    private var notebookCurrentIndex: Int {
        let tag = currentPageTag ?? "cover"
        if tag == "cover" { return 0 }
        if tag == newPageTag { return regularBoards.count + 1 }
        return (regularBoards.firstIndex(where: { $0.id.uuidString == tag }) ?? -1) + 1
    }

    private var currentPageTitle: String {
        let tag = currentPageTag ?? "cover"
        if tag == "cover" { return "表紙" }
        if let board = regularBoards.first(where: { $0.id.uuidString == tag }) {
            return board.title
        }
        return "シールボード"
    }

    // MARK: - ボードシールプレビュー

    private func boardStickerPreview(_ placements: [StickerPlacement], boardType: BoardType) -> some View {
        BoardStickerPreviewView(placements: placements, boardType: boardType)
    }

    // MARK: - アクション

    private func createBoard(title: String, boardType: BoardType) {
        let board = Board(title: title, boardType: boardType)
        board.notebookIdString = notebook.id.uuidString
        modelContext.insert(board)
        // 新規ページへスクロール（SwiftData更新後に遅延実行）
        let newId = board.id.uuidString
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.easeOut(duration: 0.4)) {
                currentPageTag = newId
            }
        }
        onBoardCreated()
    }

    private func shareBoardAsImage(_ board: Board) {
        BoardShareService.share(board, displayScale: displayScale)
    }

    private func renameBoard() {
        guard let board = boardToRename else { return }
        let title = renameBoardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        board.title = title
        board.updatedAt = Date()
        boardToRename = nil
        renameBoardTitle = ""
    }

    private func deleteBoard(_ board: Board) {
        // 表紙ボードは削除しない
        guard board.id.uuidString != notebook.coverBoardId else {
            boardToDelete = nil
            return
        }
        let deletedId = board.id
        let remaining = regularBoards.filter { $0.id != deletedId }.map { b in
            WidgetDataSyncService.generateMetadata(
                boardId: b.id, title: b.title,
                stickerCount: b.placements.count, updatedAt: b.updatedAt
            )
        }
        modelContext.delete(board)
        WidgetDataSyncService.removeBoard(boardId: deletedId, remainingMetadata: remaining)
        boardToDelete = nil
    }
}

// MARK: - ボードシールプレビュー（非同期画像読み込み）

private struct BoardStickerPreviewView: View {
    let placements: [StickerPlacement]
    var boardType: BoardType = .standard
    @State private var images: [UUID: UIImage] = [:]

    private let previewThumbnailSize: CGFloat = 200

    private var referenceCanvasSize: CGSize {
        let s = AppTheme.screenBounds
        let cardW = s.width - AppTheme.EditorLayout.horizontalPadding * 2
        let cardH = s.height - AppTheme.EditorLayout.verticalChromeHeight
        guard cardW > 0, cardH > 0 else {
            return CGSize(width: 300, height: 400)
        }
        switch boardType {
        case .standard:
            return CGSize(width: cardW, height: cardH)
        case .widgetLarge:
            return CGSize(width: cardW, height: cardW / BoardType.widgetLargeAspectRatio)
        case .widgetMedium:
            return CGSize(width: cardW, height: cardW / BoardType.widgetMediumAspectRatio)
        case .widgetSmall:
            return CGSize(width: cardW, height: cardW / BoardType.widgetSmallAspectRatio)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let canvasWidth = referenceCanvasSize.width
            let canvasHeight = referenceCanvasSize.height
            let previewScale = min(
                geo.size.width / canvasWidth,
                geo.size.height / canvasHeight
            )

            let visible = placements.sorted { $0.zIndex < $1.zIndex }

            ZStack {
                ForEach(visible) { placement in
                    if let image = images[placement.id] {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                            .scaleEffect(placement.scale)
                            .rotationEffect(.radians(placement.rotation))
                            .offset(x: placement.positionX, y: placement.positionY)
                    }
                }
            }
            .frame(width: canvasWidth, height: canvasHeight)
            .scaleEffect(previewScale)
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .task {
            let thumbSize = previewThumbnailSize
            let cache = ImageCacheManager.shared
            let loaded = await Task.detached {
                var result: [UUID: UIImage] = [:]
                for placement in placements {
                    if let image = cache.processedThumbnail(
                        for: placement.imageFileName,
                        size: thumbSize,
                        filter: placement.filter,
                        borderWidth: placement.borderWidth,
                        borderColorHex: placement.borderColorHex
                    ) {
                        result[placement.id] = image
                    }
                }
                return result
            }.value
            images = loaded
        }
        .onDisappear { images = [:] }
    }
}

// MARK: - ボードカード背景（カスタム背景画像の非同期読み込み対応）

private struct BoardCardBackground: View {
    let config: BackgroundPatternConfig
    @State private var customImage: UIImage?

    var body: some View {
        BoardBackgroundView(config: config, customImage: customImage)
            .task(id: config.customImageFileName) {
                if config.patternType == .custom, let fileName = config.customImageFileName {
                    customImage = await Task.detached {
                        BackgroundImageStorage.load(fileName: fileName)
                    }.value
                } else {
                    customImage = nil
                }
            }
    }
}

// MARK: - 新規ボード作成シート

private struct NewBoardSheet: View {
    let onConfirm: (String, BoardType) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedType: BoardType = .standard

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ページ名")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)

                    TextField("例: 夏のシール集め", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ページの種類")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)

                    VStack(spacing: 10) {
                        boardTypeRow(
                            type: .standard,
                            title: "壁紙・画像用",
                            subtitle: "縦長キャンバス。写真ライブラリへ保存",
                            icon: "photo.fill",
                            previewAspectRatio: 0.56
                        )
                        boardTypeRow(
                            type: .widgetLarge,
                            title: "ウィジェット大用",
                            subtitle: "ホーム画面の大サイズウィジェットにピッタリ",
                            icon: "square.fill",
                            previewAspectRatio: BoardType.widgetLargeAspectRatio
                        )
                        boardTypeRow(
                            type: .widgetMedium,
                            title: "ウィジェット中用",
                            subtitle: "ホーム画面の中サイズウィジェットにピッタリ",
                            icon: "apps.iphone",
                            previewAspectRatio: BoardType.widgetMediumAspectRatio
                        )
                        boardTypeRow(
                            type: .widgetSmall,
                            title: "ウィジェット小用",
                            subtitle: "ホーム画面の小サイズウィジェットにピッタリ",
                            icon: "square.fill",
                            previewAspectRatio: BoardType.widgetSmallAspectRatio
                        )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .background(AppTheme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("新しいページ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("作成") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onConfirm(trimmed, selectedType)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.accent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func boardTypeRow(type: BoardType, title: LocalizedStringKey, subtitle: LocalizedStringKey, icon: String, previewAspectRatio: CGFloat) -> some View {
        let isSelected = selectedType == type
        return Button {
            selectedType = type
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Color.clear
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? AppTheme.accent.opacity(0.15) : AppTheme.backgroundCard)
                        .aspectRatio(previewAspectRatio, contentMode: .fit)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    isSelected ? AppTheme.accent : AppTheme.textTertiary.opacity(0.3),
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        }
                        .overlay {
                            Image(systemName: icon)
                                .font(.system(size: 14))
                                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textTertiary)
                        }
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textTertiary.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AppTheme.accent.opacity(0.06) : AppTheme.backgroundCard)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? AppTheme.accent.opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    let notebook = Notebook(title: "プレビュー手帳")
    NavigationStack {
        HomeView(notebook: notebook, hideTabBar: .constant(false), deepLinkBoardId: .constant(nil))
    }
    .modelContainer(for: [Sticker.self, Board.self, Notebook.self], inMemory: true)
}
