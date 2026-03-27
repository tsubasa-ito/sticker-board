import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Board.updatedAt, order: .reverse) private var boards: [Board]

    private let newBoardCardID = "new-board"

    @Binding var hideTabBar: Bool

    @State private var showingNewBoard = false
    @State private var newBoardTitle = ""
    @State private var scrolledID: String?
    @State private var animateIn = false
    @State private var selectedBoard: Board?
    @State private var boardToRename: Board?
    @State private var showingRenameBoard = false
    @State private var renameBoardTitle = ""
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
            }
        }
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView()
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
        .alert("新しいボード", isPresented: $showingNewBoard) {
            TextField("ボード名", text: $newBoardTitle)
            Button("作成") { createBoard() }
            Button("キャンセル", role: .cancel) { newBoardTitle = "" }
        } message: {
            Text("ボードの名前を入力してください")
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateIn = true
            }
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
        .contentMargins(.horizontal, 20)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 30)
    }

    // MARK: - ボードカード

    private func boardCard(_ board: Board) -> some View {
        VStack(spacing: 0) {
            // プレビューエリア
            ZStack {
                // ボード背景パターン
                BoardBackgroundView(config: board.backgroundPattern)

                // シールプレビュー
                if board.placements.isEmpty {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.textTertiary.opacity(0.3))
                } else {
                    boardStickerPreview(board.placements)
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

                                Divider()

                                Button(role: .destructive) {
                                    modelContext.delete(board)
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
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                    }
                }
            }
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 12)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .containerRelativeFrame(.horizontal)
    }

    // MARK: - ボードシールプレビュー

    /// ボードエディタと同じレイアウトを縮小して表示する
    private func boardStickerPreview(_ placements: [StickerPlacement]) -> some View {
        BoardStickerPreviewView(placements: placements)
    }

    // MARK: - 新規ボードカード

    private var newBoardCard: some View {
        Button {
            if !SubscriptionManager.shared.isProUser && boards.count >= 1 {
                showingPaywall = true
            } else {
                showingNewBoard = true
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
                            .fill(AppTheme.accent)
                            .frame(width: 64, height: 64)
                            .shadow(
                                color: AppTheme.accent.opacity(0.3),
                                radius: 12, x: 0, y: 6
                            )

                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
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
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
        }
        .buttonStyle(.plain)
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
                    showingNewBoard = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 64, height: 64)
                        .shadow(
                            color: AppTheme.accent.opacity(0.3),
                            radius: 12, x: 0, y: 6
                        )

                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }

    // MARK: - アクション

    private func createBoard() {
        let title = newBoardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let board = Board(title: title)
        modelContext.insert(board)
        newBoardTitle = ""
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
}

// MARK: - ボードシールプレビュー（非同期画像読み込み）

private struct BoardStickerPreviewView: View {
    let placements: [StickerPlacement]
    @State private var images: [UUID: UIImage] = [:]

    /// プレビュー用サムネイルサイズ（カルーセル内なので小さくてOK）
    private let previewThumbnailSize: CGFloat = 200

    var body: some View {
        GeometryReader { geo in
            let canvasWidth = UIScreen.main.bounds.width
            let canvasHeight = UIScreen.main.bounds.height
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

#Preview {
    NavigationStack {
        HomeView(hideTabBar: .constant(false))
    }
    .modelContainer(for: [Sticker.self, Board.self], inMemory: true)
}
