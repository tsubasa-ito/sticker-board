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

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    // トップバーのスペーサー
                    Color.clear.frame(height: 64)

                    heroSection

                    if boards.isEmpty {
                        emptyState
                    } else {
                        boardCarousel
                            .padding(.top, 8)

                        pageIndicators
                            .padding(.top, 20)
                    }

                    Spacer(minLength: 120)
                }
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .top) {
            topBar
        }
        .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - トップバー

    private var topBar: some View {
        HStack {
            Text("シールボード")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.headerGradient)

            Spacer()

            Button {
                showingNewBoard = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("新しく作る")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - ヒーローセクション

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("マイコレクション")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("お気に入りのシールを撮影して、自分だけのボードを作ろう")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }

    // MARK: - ボードカルーセル

    private var boardCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 16) {
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
        .contentMargins(.horizontal, 32)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 30)
    }

    // MARK: - ボードカード

    private func boardCard(_ board: Board) -> some View {
        VStack(spacing: 0) {
            // プレビューエリア
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.backgroundCanvas)

                // ドットグリッドパターン
                Canvas { context, size in
                    let spacing: CGFloat = 18
                    let dotSize: CGFloat = 1.5
                    let color = Color(hex: 0xE5DDD0)
                    for x in stride(from: spacing, to: size.width, by: spacing) {
                        for y in stride(from: spacing, to: size.height, by: spacing) {
                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: x - dotSize / 2,
                                    y: y - dotSize / 2,
                                    width: dotSize,
                                    height: dotSize
                                )),
                                with: .color(color)
                            )
                        }
                    }
                }

                // シールプレビュー
                if board.placements.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.textTertiary.opacity(0.4))
                        Text("シールを配置しよう")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                } else {
                    boardStickerPreview(board.placements)
                }

                // ボトムグラデーション
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .aspectRatio(4.0 / 5.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            // 情報セクション
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(board.title)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text("\(board.placements.count)枚のシール")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.accent.opacity(0.12))
                            .clipShape(Capsule())

                        Text(board.updatedAt.formatted(.relative(presentation: .named)))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
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
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(10)
                        .background(AppTheme.backgroundPrimary.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            .padding(20)
        }
        .background(AppTheme.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
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
            showingNewBoard = true
        } label: {
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            AppTheme.accent.opacity(0.25),
                            style: StrokeStyle(lineWidth: 3, dash: [10, 8])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(AppTheme.backgroundCard.opacity(0.6))
                        )

                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.headerGradient)
                                .frame(width: 72, height: 72)
                                .shadow(
                                    color: AppTheme.accent.opacity(0.3),
                                    radius: 12, x: 0, y: 6
                                )

                            Image(systemName: "plus")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 6) {
                            Text("新しくボードを作る")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.accent)

                            Text("新しい思い出をスクラップしよう")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .aspectRatio(4.0 / 5.0, contentMode: .fit)

                // 情報セクションと同じ高さのスペーサー
                Color.clear.frame(height: 84)
            }
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
        VStack(spacing: 24) {
            Spacer().frame(height: 48)

            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.accent.opacity(0.5))
            }

            VStack(spacing: 8) {
                Text("ボードがまだありません")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("ボードを作ってシールを\n自由に配置しましょう")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingNewBoard = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text("ボードを作る")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(AppTheme.headerGradient)
                .clipShape(Capsule())
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
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
            let loaded = await Task.detached {
                var result: [UUID: UIImage] = [:]
                for placement in placements {
                    if let image = ImageStorage.load(fileName: placement.imageFileName) {
                        result[placement.id] = image
                    }
                }
                return result
            }.value
            images = loaded
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(hideTabBar: .constant(false))
    }
    .modelContainer(for: [Sticker.self, Board.self], inMemory: true)
}
