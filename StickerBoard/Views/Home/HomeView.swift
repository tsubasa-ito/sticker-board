import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayScale) private var displayScale
    @Query(sort: \Board.createdAt, order: .forward) private var boards: [Board]

    private let newBoardCardID = "new-board"

    @Binding var hideTabBar: Bool
    @Binding var deepLinkBoardId: UUID?
    var onBoardCreated: () -> Void = {}

    @State private var showingBoardTypePicker = false
    @State private var scrolledID: String?
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
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if boards.isEmpty {
                    emptyState
                        .frame(maxHeight: .infinity)
                } else {
                    Spacer(minLength: 8)

                    boardCarousel

                    pageIndicators
                        .padding(.top, 16)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("シールボード")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityLabel("設定")
                .accessibilityHint("設定画面を開きます")
            }
            ToolbarItem(placement: .principal) {
                Text("シールボード")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingOnboarding = true
                } label: {
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
        .navigationDestination(item: $selectedBoard) { board in
            BoardEditorView(board: board)
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateIn = true
            }
        }
        .onChange(of: deepLinkBoardId) {
            guard let boardId = deepLinkBoardId else { return }
            if let board = boards.first(where: { $0.id == boardId }) {
                selectedBoard = board
            }
            deepLinkBoardId = nil
        }
    }

    // MARK: - ボードカルーセル

    private var boardCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(boards) { board in
                    boardCard(board)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBoard = board
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(board.title)、シール\(board.placements.count)枚")
                        .accessibilityHint("タップしてボードを編集します")
                        .accessibilityAddTraits(.isButton)
                        .id(board.id.uuidString)
                }

                // 新規ボード作成カード
                newBoardCard
                    .id(newBoardCardID)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrolledID)
        .contentMargins(.horizontal, AppTheme.EditorLayout.horizontalPadding)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 30)
    }

    // MARK: - ボードカード

    /// エディタのキャンバスと同じ比率を算出（画面からナビバー・ツールバー・パディング分を引く）
    private var boardCardAspectRatio: CGFloat {
        let screen = AppTheme.screenBounds
        let canvasWidth = screen.width - (AppTheme.EditorLayout.horizontalPadding * 2)
        let canvasHeight = screen.height - AppTheme.EditorLayout.verticalChromeHeight
        // 起動直後に screenBounds が未確定の場合は妥当なデフォルト比率を返す
        guard canvasWidth > 0, canvasHeight > 0 else { return 0.75 }
        return canvasWidth / canvasHeight
    }

    private func boardCard(_ board: Board) -> some View {
        let cardAspectRatio: CGFloat = {
            switch board.boardType {
            case .widgetLarge: return BoardType.widgetLargeAspectRatio
            case .widgetMedium: return BoardType.widgetMediumAspectRatio
            case .standard: return boardCardAspectRatio
            }
        }()
        return VStack(spacing: 0) {
            // プレビューエリア
            ZStack {
                // ボード背景パターン
                BoardCardBackground(config: board.backgroundPattern)

                // シールプレビュー
                if board.placements.isEmpty {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.textTertiary.opacity(0.3))
                } else {
                    boardStickerPreview(board.placements, boardType: board.boardType)
                }

                // ボトムグラデーション + タイトルオーバーレイ
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .overlay(alignment: .bottomLeading) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(board.title)
                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                                Text("\(board.placements.count)枚")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                            }

                            Spacer()

                            Menu {
                                Button {
                                    boardToRename = board
                                    renameBoardTitle = board.title
                                    showingRenameBoard = true
                                } label: {
                                    Label("名前を変更", systemImage: "pencil")
                                }

                                Button {
                                    shareBoardAsImage(board)
                                } label: {
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
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(10)
                                    .background(.ultraThinMaterial.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("メニュー")
                            .accessibilityHint("ボードの名前変更や削除ができます")
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                    }
                }
            }
            .aspectRatio(cardAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 12)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .containerRelativeFrame(.horizontal)
    }

    // MARK: - ボードシールプレビュー

    /// ボードエディタと同じレイアウトを縮小して表示する
    private func boardStickerPreview(_ placements: [StickerPlacement], boardType: BoardType) -> some View {
        BoardStickerPreviewView(placements: placements, boardType: boardType)
    }

    // MARK: - 新規ボードカード

    private var newBoardCard: some View {
        Button {
            if !SubscriptionManager.shared.isProUser && boards.count >= 1 {
                showingPaywall = true
            } else {
                showingBoardTypePicker = true
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(
                        AppTheme.accent.opacity(0.25),
                        style: StrokeStyle(lineWidth: 2.5, dash: [12, 8])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(AppTheme.backgroundCard.opacity(0.5))
                    )

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(AppTheme.accent.opacity(0.18))
                            .frame(width: 62, height: 62)
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }

                    VStack(spacing: 6) {
                        Text("新しいボードを作る")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("シールを撮影して\n自分だけのボードを作ろう")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
            }
            .aspectRatio(boardCardAspectRatio, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("新しいボードを作る")
        .accessibilityHint("タップして新しいボードを作成します")
        .containerRelativeFrame(.horizontal)
    }

    // MARK: - ページインジケーター

    private var pageIndicators: some View {
        HStack(spacing: 6) {
            let totalPages = boards.count + 1
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentPageIndex
                            ? AppTheme.accent
                            : AppTheme.accent.opacity(0.2)
                    )
                    .frame(
                        width: index == currentPageIndex ? 24 : 8,
                        height: 8
                    )
                    .animation(.spring(duration: 0.3), value: currentPageIndex)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ページ \(currentPageIndex + 1) / \(boards.count + 1)")
        .accessibilityValue(currentPageIndex < boards.count ? boards[currentPageIndex].title : "新しいボードを作る")
    }

    private var currentPageIndex: Int {
        guard let id = scrolledID else { return 0 }
        if let index = boards.firstIndex(where: { $0.id.uuidString == id }) {
            return index
        }
        if id == newBoardCardID {
            return boards.count
        }
        return 0
    }

    // MARK: - 空の状態

    private var emptyState: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.06))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(spacing: 6) {
                Text("新しいボードを作る")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("シールを撮影して\n自分だけのボードを作ろう")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                if !SubscriptionManager.shared.isProUser && boards.count >= 1 {
                    showingPaywall = true
                } else {
                    showingBoardTypePicker = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .accessibilityHidden(true)
                    Text("ボードを作る")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(AppTheme.accent, in: Capsule())
                .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, y: 6)
            }
            .accessibilityLabel("新しいボードを作る")
            .accessibilityHint("タップして新しいボードを作成します")
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }

    // MARK: - アクション

    private func createBoard(title: String, boardType: BoardType) {
        let board = Board(title: title, boardType: boardType)
        modelContext.insert(board)
        onBoardCreated()
    }

    // MARK: - SNSシェア

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
        let deletedId = board.id
        // delete 前にメタデータを生成（@Query が stale になる前に）
        let remaining = boards.filter { $0.id != deletedId }.map { b in
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

    /// プレビュー用サムネイルサイズ（カルーセル内なので小さくてOK）
    private let previewThumbnailSize: CGFloat = 200

    /// エディタで使われるキャンバス参照サイズ（シール座標の基準）
    /// シール positionX/Y はキャンバス中心からのオフセット。キャンバスとカードは中心が一致するため、
    /// standardは背景（カード）サイズを参照し previewScale=1 で座標をそのままマッピングする。
    private var referenceCanvasSize: CGSize {
        let s = AppTheme.screenBounds
        let cardW = s.width - AppTheme.EditorLayout.horizontalPadding * 2
        let cardH = s.height - AppTheme.EditorLayout.verticalChromeHeight
        switch boardType {
        case .standard:
            return CGSize(width: cardW, height: cardH)
        case .widgetLarge:
            return CGSize(width: cardW, height: cardW / BoardType.widgetLargeAspectRatio)
        case .widgetMedium:
            return CGSize(width: cardW, height: cardW / BoardType.widgetMediumAspectRatio)
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
        .onDisappear {
            images = [:]
        }
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
                // ボード名入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("ボード名")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)

                    TextField("例: 夏のシール集め", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                }

                // ボードタイプ選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("ボードの種類")
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
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .background(AppTheme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("新しいボード")
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

    /// ボードタイプ選択行（HStack: プレビュー + テキスト + チェックマーク）
    private func boardTypeRow(type: BoardType, title: LocalizedStringKey, subtitle: LocalizedStringKey, icon: String, previewAspectRatio: CGFloat) -> some View {
        let isSelected = selectedType == type
        return Button {
            selectedType = type
        } label: {
            HStack(spacing: 14) {
                // アスペクト比を固定枠内で可視化（縦長 vs 横長の違いが直感的にわかる）
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
    NavigationStack {
        HomeView(hideTabBar: .constant(false), deepLinkBoardId: .constant(nil))
    }
    .modelContainer(for: [Sticker.self, Board.self], inMemory: true)
}
