import SwiftUI
import SwiftData

/// 手帳一覧画面 - 複数の手帳をバインダーカードで表示する
struct NotebookListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Notebook.createdAt, order: .forward) private var notebooks: [Notebook]
    @Query(sort: \Board.createdAt, order: .forward) private var allBoards: [Board]

    @Binding var hideTabBar: Bool
    @Binding var deepLinkBoardId: UUID?

    @State private var selectedNotebook: Notebook?
    @State private var showingNewNotebookSheet = false
    @State private var newNotebookTitle = ""
    @State private var animateIn = false
    @State private var showingSettings = false
    @State private var showingOnboarding = false

    var body: some View {
        ZStack {
            AppTheme.notebookCover.ignoresSafeArea()

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                    spacing: 20
                ) {
                    ForEach(notebooks) { notebook in
                        notebookCard(notebook)
                            .onTapGesture { selectedNotebook = notebook }
                    }

                    // 新規手帳カード
                    newNotebookCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
        }
        .navigationTitle("マイ手帳")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityLabel("設定")
            }
            ToolbarItem(placement: .principal) {
                Text("マイ手帳")
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
            }
        }
        .navigationDestination(item: $selectedNotebook) { notebook in
            HomeView(
                notebook: notebook,
                hideTabBar: $hideTabBar,
                deepLinkBoardId: $deepLinkBoardId
            )
            .onAppear { }
        }
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView()
                .onAppear { hideTabBar = true }
                .onDisappear { hideTabBar = false }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .alert("新しい手帳", isPresented: $showingNewNotebookSheet) {
            TextField("手帳の名前", text: $newNotebookTitle)
            Button("作成") { createNotebook() }
            Button("キャンセル", role: .cancel) { newNotebookTitle = "" }
        } message: {
            Text("新しい手帳の名前を入力してください")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { animateIn = true }
        }
        .onChange(of: deepLinkBoardId) {
            guard let boardId = deepLinkBoardId else { return }
            // ディープリンク: 対象ボードが属する手帳に遷移
            if let board = allBoards.first(where: { $0.id == boardId }),
               let notebook = notebooks.first(where: { $0.id.uuidString == board.notebookIdString }) {
                selectedNotebook = notebook
            }
        }
    }

    // MARK: - 手帳カード

    private func notebookCard(_ notebook: Notebook) -> some View {
        let pageCount = pageCount(for: notebook)
        let coverBoard = coverBoard(for: notebook)

        return HStack(spacing: 0) {
            // リング列（手帳外観として常に左に表示）
            NotebookRingView()
                .frame(width: 32)

            ZStack {
                // 表紙コンテンツ
                if let cover = coverBoard {
                    NotebookCoverBackground(config: cover.backgroundPattern)
                    if !cover.placements.isEmpty {
                        notebookStickerPreview(cover.placements, boardType: cover.boardType)
                    }
                } else {
                    AppTheme.notebookPage
                }

                // ページ外枠
                Rectangle()
                    .strokeBorder(AppTheme.notebookSpine.opacity(0.3), lineWidth: 1)

                // 下部タイトル
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(notebook.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary.opacity(0.85))
                                .lineLimit(1)
                            Text(pageCount == 0 ? "ページなし" : pageCount == 1 ? "1ページ" : "\(pageCount)ページ")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .padding(.leading, 16)
                        .padding(.bottom, 16)

                        Spacer()

                        // 手帳メニュー
                        Menu {
                            Button(role: .destructive) {
                                deleteNotebook(notebook)
                            } label: {
                                Label("手帳を削除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.55))
                                .padding(9)
                                .background(.ultraThinMaterial, in: Circle())
                                .padding(.trailing, 14)
                                .padding(.bottom, 14)
                        }
                        .accessibilityLabel("手帳メニュー")
                    }
                }
            }
            .shadow(color: .black.opacity(0.05), radius: 6, x: 3, y: 0)
        }
        // A4縦横比（210:297）
        .aspectRatio(210.0 / 297.0, contentMode: .fit)
        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 5)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notebook.title)、\(pageCount)ページ")
        .accessibilityHint("タップして手帳を開きます")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - 新規手帳カード

    private var newNotebookCard: some View {
        HStack(spacing: 0) {
            // リング列（プレースホルダー）
            ZStack {
                AppTheme.notebookSpine.opacity(0.4)
                    .frame(width: 32)
            }
            .frame(width: 32)

            ZStack {
                AppTheme.notebookPage
                    .overlay {
                        Rectangle()
                            .strokeBorder(AppTheme.accent.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [12, 8]))
                            .padding(20)
                    }

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.08))
                            .frame(width: 60, height: 60)
                        Circle()
                            .strokeBorder(AppTheme.accent.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                            .frame(width: 60, height: 60)
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(AppTheme.accent)
                    }
                    Text("新しい手帳を追加")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        // A4縦横比（210:297）で統一
        .aspectRatio(210.0 / 297.0, contentMode: .fit)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture { showingNewNotebookSheet = true }
        .accessibilityLabel("新しい手帳を追加")
        .accessibilityHint("タップして手帳を作成します")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - ヘルパー

    private func coverBoard(for notebook: Notebook) -> Board? {
        allBoards.first { $0.id.uuidString == notebook.coverBoardId }
    }

    private func pageCount(for notebook: Notebook) -> Int {
        allBoards.filter {
            $0.notebookIdString == notebook.id.uuidString &&
            $0.id.uuidString != notebook.coverBoardId
        }.count
    }

    private func notebookStickerPreview(_ placements: [StickerPlacement], boardType: BoardType) -> some View {
        NotebookCardStickerPreview(placements: placements, boardType: boardType)
    }

    // MARK: - アクション

    private func createNotebook() {
        let title = newNotebookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            newNotebookTitle = ""
            return
        }
        let notebook = Notebook(title: title)
        modelContext.insert(notebook)
        newNotebookTitle = ""
        // 作成した手帳を開く
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            selectedNotebook = notebook
        }
    }

    private func deleteNotebook(_ notebook: Notebook) {
        // この手帳に属するボードを全て削除
        let notebookId = notebook.id.uuidString
        let boards = allBoards.filter { $0.notebookIdString == notebookId }
        for board in boards {
            modelContext.delete(board)
        }
        modelContext.delete(notebook)
    }
}

// MARK: - 手帳カード用シールプレビュー（非同期）

private struct NotebookCardStickerPreview: View {
    let placements: [StickerPlacement]
    var boardType: BoardType = .standard
    @State private var images: [UUID: UIImage] = [:]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(placements.sorted { $0.zIndex < $1.zIndex }) { placement in
                    if let image = images[placement.id] {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .scaleEffect(placement.scale)
                            .rotationEffect(.radians(placement.rotation))
                            .offset(x: placement.positionX * geo.size.width / 300,
                                    y: placement.positionY * geo.size.height / 400)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            let cache = ImageCacheManager.shared
            var result: [UUID: UIImage] = [:]
            for placement in placements {
                if let image = cache.processedThumbnail(
                    for: placement.imageFileName,
                    size: 120,
                    filter: placement.filter,
                    borderWidth: placement.borderWidth,
                    borderColorHex: placement.borderColorHex
                ) {
                    result[placement.id] = image
                }
            }
            images = result
        }
        .onDisappear { images = [:] }
    }
}

// MARK: - 表紙背景（非同期カスタム画像対応）

private struct NotebookCoverBackground: View {
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

#Preview {
    NavigationStack {
        NotebookListView(hideTabBar: .constant(false), deepLinkBoardId: .constant(nil))
    }
    .modelContainer(for: [Sticker.self, Board.self, Notebook.self], inMemory: true)
}
